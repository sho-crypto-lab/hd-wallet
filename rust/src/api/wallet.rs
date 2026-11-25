use crate::wallet::{
    hd_wallet::{HdWallet, Network},
    mnemonic,
};

/// Flutterから指定するBitcoinネットワーク。
pub enum WalletNetwork {
    Bitcoin,
    Testnet,
    Signet,
    Regtest,
}

impl From<WalletNetwork> for Network {
    fn from(network: WalletNetwork) -> Self {
        match network {
            WalletNetwork::Bitcoin => Self::Bitcoin,
            WalletNetwork::Testnet => Self::Testnet,
            WalletNetwork::Signet => Self::Signet,
            WalletNetwork::Regtest => Self::Regtest,
        }
    }
}

/// 秘密鍵やseedを含まない、受取アドレスとその派生パス。
pub struct ReceiveAddress {
    pub address: String,
    pub path: String,
}

/// 英語12単語のBIP-39リカバリーフレーズを新規生成する。
pub fn generate_mnemonic() -> String {
    mnemonic::generate()
}

/// 英語BIP-39フレーズの単語数・単語・チェックサムを検証する。
pub fn validate_mnemonic(phrase: String) -> bool {
    mnemonic::validate(&phrase)
}

/// フレーズからウォレットを復元し、BIP-84の受取アドレスを返す。
/// パスフレーズを使用しない場合は空文字列を指定する。
/// accountとindexは0以上2^31未満。フレーズや鍵の永続保存は行わない。
pub fn derive_receive_address(
    phrase: String,
    passphrase: String,
    network: WalletNetwork,
    account: u32,
    index: u32,
) -> Result<ReceiveAddress, String> {
    let wallet = HdWallet::from_phrase(&phrase, &passphrase, network.into())
        .map_err(|error| error.to_string())?;
    let path = wallet
        .receive_path(account, index)
        .map_err(|error| error.to_string())?;
    let address = wallet
        .address_at_path(&path.to_string())
        .map_err(|error| error.to_string())?;
    Ok(ReceiveAddress {
        address: address.to_string(),
        path: format!("m/{path}"),
    })
}
