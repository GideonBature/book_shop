use core::starknet::ContractAddress;

#[starknet::interface]
trait IWallet<TWallet> {
    fn get_balance(self: @TWallet) -> felt252;
    fn recieve(ref self: TWallet, recipient: ContractAddress, amount: felt252) -> bool;
    fn refund(ref self: TWallet, owner: ContractAddress, amount: felt252) -> bool;
}

#[starknet::contract]
pub mod Wallet {
    use core::starknet::get_caller_address;
    use starknet::storage::{ StoragePointerReadAccess, StoragePointerWriteAccess };

    #[storage]
    struct Storage {
        balance: felt252,
        cashier: ContractAddress,
    }
    
    #[constructor]
    fn constructor(ref self: ContractState, cashier: ContractAddress, balance: felt252) {
        self.cashier.write(cashier);
        self.balance.write(0);
    }
    
    #[abi(embed_v0)]
    impl WalletImpl of super::IWallet<ContractState> {


        fn get_balance(self: @ContractState) -> felt252 {
            let caller = get_caller_address();
            let owner = self.cashier.read();
            assert(caller == owner, 'Caller is not the owner');
            self.balance.read()
        }

        fn recieve(ref self: ContractState, recipient: ContractAddress, amount: felt252) -> bool {
            let caller = get_caller_address();
            let owner = self.cashier.read();
            assert(caller == owner, 'Caller is not the owner');

            let mut balance = self.balance.read();
            balance += amount;
            self.balance.write(balance);
            true
        }

        fn refund(ref self: ContractState, owner: ContractAddress, amount: felt252) -> bool {
            let caller = get_caller_address();
            assert(caller == owner, 'Caller is not the owner');
            let mut balance = self.balance.read();
            balance -= amount;
            self.balance.write(balance);
            true
        }
    }
}
