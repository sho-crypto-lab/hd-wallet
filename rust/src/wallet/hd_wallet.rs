use super::{error::WalletError, mnemonic};
use bitcoin::bip32::{ChildNumber, DerivationPath, Xpriv};
use bitcoin::secp256k1::{PublicKey, Secp256k1};
use bitcoin::{Address, CompressedPublicKey};
use unicode_normalization::UnicodeNormalization;

pub use bitcoin::Network;

pub struct HdWallet {
    network: Network,
    // マスター秘密鍵とチェーンコードを含む拡張秘密鍵を保持する。
    master_key: Xpriv,
}

impl HdWallet {
    /// ネットワークとseedを指定してウォレットを作成する。
    pub fn new(network: Network, seed: &[u8]) -> Result<Self, WalletError> {
        Self::from_seed(seed, network)
    }

    /// BIP-32に従い、seedからマスター秘密鍵とチェーンコードを生成する。
    pub fn from_seed(seed: &[u8], network: Network) -> Result<Self, WalletError> {
        if !(16..=64).contains(&seed.len()) {
            return Err(WalletError::InvalidSeedLength);
        }
        let master_key = Xpriv::new_master(network, seed)?;
        Ok(Self {
            network,
            master_key,
        })
    }

    /// 英語フレーズを検証し、パスフレーズと合わせてウォレットを復元する。
    /// パスフレーズを使わない場合は空文字列を渡す。
    pub fn from_phrase(
        phrase: &str,
        passphrase: &str,
        network: Network,
    ) -> Result<Self, WalletError> {
        if !mnemonic::validate(phrase) {
            return Err(WalletError::InvalidPhrase);
        }
        // 入力時の前後の空白・連続する空白を、単語間の半角スペースに揃える。
        let normalized: String = phrase.nfkd().collect();
        let phrase = normalized.split_whitespace().collect::<Vec<_>>().join(" ");
        let seed = mnemonic::to_seed(&phrase, passphrase);
        Self::from_seed(&seed, network)
    }

    pub fn network(&self) -> Network {
        self.network
    }

    /// マスター拡張秘密鍵を取得する。チェーンコードもこの値に含まれる。
    pub fn master_key(&self) -> &Xpriv {
        &self.master_key
    }

    /// マスター鍵を基点に、指定した派生パスの拡張秘密鍵を生成する。
    pub fn derive_private_key(&self, path: &str) -> Result<Xpriv, WalletError> {
        let path: DerivationPath = path.parse()?;
        Ok(self.master_key.derive_priv(&Secp256k1::new(), &path)?)
    }

    /// 指定した派生パスの圧縮公開鍵を生成する。
    pub fn derive_public_key(&self, path: &str) -> Result<CompressedPublicKey, WalletError> {
        let key = self.derive_private_key(path)?;
        Ok(CompressedPublicKey(PublicKey::from_secret_key(
            &Secp256k1::new(),
            &key.private_key,
        )))
    }

    /// 指定した派生パスのNative SegWit（P2WPKH）アドレスを生成する。
    pub fn address_at_path(&self, path: &str) -> Result<Address, WalletError> {
        let public_key = self.derive_public_key(path)?;
        Ok(Address::p2wpkh(&public_key, self.network))
    }

    /// BIP-84の受取用パス m/84'/coin_type'/account'/0/index を返す。
    /// メインネットのcoin_typeは0、テスト用ネットワークは1になる。
    pub fn receive_path(&self, account: u32, index: u32) -> Result<DerivationPath, WalletError> {
        let coin_type = if self.network == Network::Bitcoin {
            0
        } else {
            1
        };
        Ok(DerivationPath::from(vec![
            ChildNumber::from_hardened_idx(84)?,
            ChildNumber::from_hardened_idx(coin_type)?,
            ChildNumber::from_hardened_idx(account)?,
            ChildNumber::from_normal_idx(0)?,
            ChildNumber::from_normal_idx(index)?,
        ]))
    }

    /// 指定したアカウント・インデックスのBIP-84受取アドレスを生成する。
    pub fn receive_address(&self, account: u32, index: u32) -> Result<Address, WalletError> {
        let path = self.receive_path(account, index)?;
        self.address_at_path(&path.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const PHRASE: &str = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    // BIP-32の既知のseedから、マスター鍵と強化・通常派生の結果が仕様と一致することを確認する。
    #[test]
    fn matches_bip32_master_and_child_vectors() {
        // 出典: https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#test-vector-1
        let seed: Vec<u8> = (0..16).collect();
        let wallet = HdWallet::new(Network::Bitcoin, &seed).unwrap();
        let vectors = [
            ("m", "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"),
            ("m/0'", "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7"),
            ("m/0'/1", "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs"),
        ];
        for (path, expected) in vectors {
            assert_eq!(
                wallet.derive_private_key(path).unwrap().to_string(),
                expected
            );
        }
        // 拡張秘密鍵の一致には、秘密鍵だけでなくチェーンコードの一致も含まれる。
        assert_eq!(wallet.master_key().to_string(), vectors[0].1);
    }

    // BIP-84の既知のフレーズから、受取アドレス2件とお釣り用アドレスを確認する。
    #[test]
    fn matches_bip84_addresses_and_keys() {
        // 出典: https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki#test-vectors
        let wallet = HdWallet::from_phrase(PHRASE, "", Network::Bitcoin).unwrap();
        assert_eq!(
            wallet.receive_path(0, 0).unwrap(),
            "m/84'/0'/0'/0/0".parse::<DerivationPath>().unwrap()
        );
        assert_eq!(
            wallet.receive_address(0, 0).unwrap().to_string(),
            "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"
        );
        assert_eq!(
            wallet.receive_address(0, 1).unwrap().to_string(),
            "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g"
        );
        assert_eq!(
            wallet
                .address_at_path("m/84'/0'/0'/1/0")
                .unwrap()
                .to_string(),
            "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el"
        );
        let path = "m/84'/0'/0'/0/0";
        assert_eq!(
            wallet.derive_public_key(path).unwrap().to_string(),
            "0330d54fd0dd420a6e5f8d3624f5f3482cae350f79d5f0753bf5beef9c2d91af3c"
        );
        assert_eq!(
            wallet.derive_private_key(path).unwrap().to_priv().to_wif(),
            "KyZpNDKnfs94vbrwhJneDi77V6jF64PWPF8x5cdJb8ifgg2DUc9d"
        );
    }

    // seedからの作成とフレーズからの復元が一致し、パスフレーズを変えると別の鍵になることを確認する。
    #[test]
    fn restores_the_same_wallet_from_phrase_and_seed() {
        let seed = mnemonic::to_seed(PHRASE, "TREZOR");
        let from_seed = HdWallet::from_seed(&seed, Network::Bitcoin).unwrap();
        let from_phrase = HdWallet::from_phrase(PHRASE, "TREZOR", Network::Bitcoin).unwrap();
        assert_eq!(from_seed.master_key(), from_phrase.master_key());
        let no_passphrase = HdWallet::from_phrase(PHRASE, "", Network::Bitcoin).unwrap();
        assert_ne!(from_phrase.master_key(), no_passphrase.master_key());
        let spaced = format!("  {}  ", PHRASE.replace(' ', "  "));
        assert_eq!(
            HdWallet::from_phrase(&spaced, "TREZOR", Network::Bitcoin)
                .unwrap()
                .master_key(),
            from_phrase.master_key()
        );
    }

    // ネットワークでマスター秘密鍵は変わらず、受取パスとアドレスの表現が変わることを確認する。
    #[test]
    fn uses_the_requested_network_for_paths_and_addresses() {
        let seed = mnemonic::to_seed(PHRASE, "");
        let main = HdWallet::from_seed(&seed, Network::Bitcoin).unwrap();
        for (network, prefix) in [
            (Network::Testnet, "tb1q"),
            (Network::Signet, "tb1q"),
            (Network::Regtest, "bcrt1q"),
        ] {
            let wallet = HdWallet::from_seed(&seed, network).unwrap();
            assert_eq!(wallet.network(), network);
            assert_eq!(
                wallet.master_key().private_key,
                main.master_key().private_key
            );
            assert_eq!(wallet.master_key().chain_code, main.master_key().chain_code);
            assert_eq!(
                wallet.receive_path(0, 0).unwrap(),
                "m/84'/1'/0'/0/0".parse::<DerivationPath>().unwrap()
            );
            let address = wallet.receive_address(0, 0).unwrap();
            assert!(address.to_string().starts_with(prefix));
            assert!(address.as_unchecked().is_valid_for_network(network));
            assert_ne!(
                address.script_pubkey(),
                main.receive_address(0, 0).unwrap().script_pubkey()
            );
        }
    }

    // 不正なseed長・フレーズ・派生パス・インデックスを、panicせずエラーとして返すことを確認する。
    #[test]
    fn rejects_invalid_wallet_inputs() {
        for len in [0, 15, 65] {
            assert!(matches!(
                HdWallet::from_seed(&vec![0; len], Network::Bitcoin),
                Err(WalletError::InvalidSeedLength)
            ));
        }
        for phrase in ["abandon", "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon invalid", "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon"] {
            assert!(matches!(HdWallet::from_phrase(phrase, "", Network::Bitcoin), Err(WalletError::InvalidPhrase)));
        }
        let wallet = HdWallet::from_phrase(PHRASE, "", Network::Bitcoin).unwrap();
        assert!(wallet.derive_private_key("invalid/path").is_err());
        assert!(wallet.receive_address(1 << 31, 0).is_err());
        assert!(wallet.receive_address(0, 1 << 31).is_err());
    }
}
