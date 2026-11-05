use pbkdf2::pbkdf2_hmac;
use sha2::{Digest, Sha256, Sha512};
use unicode_normalization::UnicodeNormalization;

pub fn generate() -> String {
    // ① BIP39の英語単語リストを読み込む
    const ENGLISH_WORDLIST: &str = include_str!("wordlists/english.txt");
    let words = ENGLISH_WORDLIST.split_whitespace().collect::<Vec<&str>>();

    if words.len() != 2048 {
        panic!("BIP39 wordlist must contain 2048 words");
    }

    // ② 128ビットの乱数を生成
    let mut entropy = [0u8; 16];
    getrandom::getrandom(&mut entropy).expect("Failed to generate secure random bytes");

    // ③ SHA-256でチェックサムを生成
    let hash = Sha256::digest(entropy);

    // ④ 128ビット + チェックサム4ビット
    let mut bits = String::with_capacity(132);
    for byte in entropy {
        bits.push_str(&format!("{byte:08b}"));
    }
    bits.push_str(&format!("{:04b}", hash[0] >> 4));

    // ⑤ 11ビットずつ分割して単語に変換
    let mut mnemonic = Vec::with_capacity(12);
    for i in (0..132).step_by(11) {
        let index = usize::from_str_radix(&bits[i..i + 11], 2)
            .expect("Mnemonic bits must contain only 0 and 1");
        mnemonic.push(words[index]);
    }

    mnemonic.join(" ")
}

/// 英語mnemonicの単語数・単語リスト・チェックサムが正しいか検証する。
pub fn validate(phrase: &str) -> bool {
    let normalized: String = phrase.nfkd().collect();
    let words: Vec<_> = normalized.split_whitespace().collect();
    if !matches!(words.len(), 12 | 15 | 18 | 21 | 24) {
        return false;
    }

    let wordlist: Vec<_> = include_str!("wordlists/english.txt")
        .split_whitespace()
        .collect();
    if wordlist.len() != 2048 {
        return false;
    }
    let mut bits = Vec::with_capacity(words.len() * 11);
    for word in words {
        let Some(index) = wordlist.iter().position(|entry| *entry == word) else {
            return false;
        };
        for shift in (0..11).rev() {
            bits.push(((index >> shift) & 1) as u8);
        }
    }

    // 全ビット数の32/33が元の乱数、残りがチェックサムになる。
    let entropy_bits = bits.len() * 32 / 33;
    let mut entropy = vec![0u8; entropy_bits / 8];
    for (i, bit) in bits[..entropy_bits].iter().enumerate() {
        entropy[i / 8] |= *bit << (7 - i % 8);
    }
    let hash = Sha256::digest(&entropy);
    bits[entropy_bits..]
        .iter()
        .enumerate()
        .all(|(i, bit)| *bit == (hash[0] >> (7 - i)) & 1)
}

/// mnemonicとパスフレーズから、BIP-39に従って64バイトのseedを生成する。
/// パスフレーズを使わない場合は空文字列を渡す。
/// 単語数・単語リスト・チェックサムの検証は、この関数では行わない。
pub fn to_seed(phrase: &str, passphrase: &str) -> [u8; 64] {
    // ① mnemonicとパスフレーズをNFKD形式に正規化する。
    let normalized_phrase: String = phrase.nfkd().collect();
    let normalized_passphrase: String = passphrase.nfkd().collect();

    // ② 「mnemonic」にパスフレーズを連結してソルトを作る。
    let salt = format!("mnemonic{normalized_passphrase}");

    // ③ PBKDF2-HMAC-SHA512を2048回適用し、64バイトのseedを生成する。
    let mut seed = [0u8; 64];
    pbkdf2_hmac::<Sha512>(
        normalized_phrase.as_bytes(),
        salt.as_bytes(),
        2048,
        &mut seed,
    );
    seed
}

#[cfg(test)]
mod tests {
    use super::*;

    // 単語列から元の乱数（エントロピー）を復元し、単語数とチェックサムを検証する。
    fn decode_mnemonic(mnemonic: &str) -> [u8; 16] {
        let wordlist: Vec<_> = include_str!("wordlists/english.txt")
            .split_whitespace()
            .collect();
        // BIP-39の英語単語リストが2048語あり、入力が12単語であることを確認する。
        assert_eq!(wordlist.len(), 2048);
        let words: Vec<_> = mnemonic.split_whitespace().collect();
        assert_eq!(words.len(), 12);
        // 各単語が英語リストに含まれることを確認し、リスト内の位置に変換する。
        let indices: Vec<_> = words
            .iter()
            .map(|word| wordlist.iter().position(|entry| entry == word).unwrap())
            .collect();

        // 各単語の位置を11ビットとして扱い、先頭128ビットから元の乱数を復元する。
        let mut entropy = [0u8; 16];
        for bit in 0..128 {
            let value = ((indices[bit / 11] >> (10 - bit % 11)) & 1) as u8;
            entropy[bit / 8] |= value << (7 - bit % 8);
        }
        // 最後の4ビットが、復元した乱数のSHA-256の先頭4ビットと一致することを確認する。
        assert_eq!(
            indices[11] & 0x0f,
            usize::from(Sha256::digest(entropy)[0] >> 4)
        );
        entropy
    }

    // 既知のBIP-39データ4件を使い、英語リストの順序・復元した乱数・チェックサムを検証する。
    #[test]
    fn english_wordlist_matches_known_bip39_vectors() {
        // 検証データの出典: https://github.com/trezor/python-mnemonic/blob/master/vectors.json
        // 各組は「16バイト分繰り返す値」と「対応する正しい12単語」を表す。
        let vectors = [
            (0x00, "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"),
            (0x7f, "legal winner thank year wave sausage worth useful legal winner thank yellow"),
            (0x80, "letter advice cage absurd amount doctor acoustic avoid letter advice cage above"),
            (0xff, "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"),
        ];
        for (byte, mnemonic) in vectors {
            assert_eq!(decode_mnemonic(mnemonic), [byte; 16]);
        }
    }

    // 実際に生成した結果が英語リスト内の12単語で、チェックサムも正しいことを検証する。
    #[test]
    fn generates_twelve_english_words_with_a_valid_checksum() {
        decode_mnemonic(&generate());
    }

    // ゼロ埋めの乱数に対応する各単語数のフレーズと、チェックサム不正・未知の単語を確認する。
    #[test]
    fn validates_all_bip39_word_counts() {
        for (count, last_word) in [
            (12, "about"),
            (15, "address"),
            (18, "agent"),
            (21, "admit"),
            (24, "art"),
        ] {
            let mut words = vec!["abandon"; count];
            words[count - 1] = last_word;
            let phrase = words.join(" ");
            assert!(validate(&phrase));
            assert!(validate(&format!(
                "  {}  ",
                phrase.replace(' ', "\u{3000}")
            )));
            words[count - 1] = "abandon";
            assert!(!validate(&words.join(" ")));
            words[count - 1] = "invalid";
            assert!(!validate(&words.join(" ")));
        }
        assert!(!validate(""));
        assert!(!validate(&vec!["abandon"; 13].join(" ")));
    }

    // 既知のBIP-39データ2件を使い、生成したseedの全64バイトが期待値と一致することを確認する。
    #[test]
    fn seed_matches_known_bip39_vectors() {
        // 出典: https://github.com/trezor/python-mnemonic/blob/master/vectors.json
        // これらのデータではパスフレーズに「TREZOR」を使う。
        let vectors = [
            (
                "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
            ),
            (
                "legal winner thank year wave sausage worth useful legal winner thank yellow",
                "2e8905819b8723fe2c1d161860e5ee1830318dbf49a83bd451cfb8440c28bd6fa457fe1296106559a3c80937a1c1069be3a3a5bd381ee6260e8d9739fce1f607",
            ),
        ];
        for (phrase, expected_hex) in vectors {
            let actual_hex: String = to_seed(phrase, "TREZOR")
                .iter()
                .map(|byte| format!("{byte:02x}"))
                .collect();
            assert_eq!(actual_hex, expected_hex);
        }
    }

    // mnemonicとパスフレーズの両方にNFKD正規化が適用されることを確認する。
    #[test]
    fn normalizes_phrase_and_passphrase_with_nfkd() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let expected = to_seed(phrase, "TREZOR");

        // 全角スペースは、NFKD正規化によって半角スペースに変換される。
        assert_eq!(
            to_seed(&phrase.replace(' ', "\u{3000}"), "TREZOR"),
            expected
        );
        // 全角英字は、NFKD正規化によって半角英字に変換される。
        assert_eq!(to_seed(phrase, "ＴＲＥＺＯＲ"), expected);
        // アクセント付き文字の合成形・分解形でも同じseedになる。
        assert_eq!(to_seed(phrase, "é"), to_seed(phrase, "e\u{301}"));
    }
}
