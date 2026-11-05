use bitcoin::bip32;
use std::fmt;

#[derive(Debug)]
pub enum WalletError {
    InvalidSeedLength,
    InvalidPhrase,
    Bip32(bip32::Error),
}

impl fmt::Display for WalletError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidSeedLength => write!(f, "Seed must contain 16 to 64 bytes"),
            Self::InvalidPhrase => write!(f, "Invalid English BIP39 mnemonic"),
            Self::Bip32(error) => write!(f, "{error}"),
        }
    }
}

impl std::error::Error for WalletError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Bip32(error) => Some(error),
            _ => None,
        }
    }
}

impl From<bip32::Error> for WalletError {
    fn from(error: bip32::Error) -> Self {
        Self::Bip32(error)
    }
}
