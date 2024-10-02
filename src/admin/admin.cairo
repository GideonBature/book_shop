use core::starknet::ContractAddress;

#[starknet::interface]
trait IAdmin {
    fn get_admin(self: @ContractState) -> ContractAddress;
    fn set_admin(ref self: ContractState, new_admin: ContractAddress);
    fn renounce_admin(ref self: ContractState);
}

mod Errors {
    pub const NOT_ADMIN: felt252 = "Caller not admin";
    pub const NOT_OWNER: felt252 = "Caller not owner";
    Pub const ZERO_ADDRESS_OWNER: felt252 = "Owner cannot be zero";
}

#[starknet::component]
pub mod admin_component {
    use core::num::traits::Zero;
    use core::starknet::{ContractAddress, get_caller_address, storage::{StoragePointerReadAccess, StoragePointerWriteAccess}};
    use super::{IAdmin, Errors};

    #[storage]
    pub struct Storage {
        admin: ContractAddress,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AdminSet: AdminSet,
        AdminRenounced: AdminRenounced,
        OwnershipInitialized: OwnerInitialized,
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminSet {
        new_admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminRenounced {
        previous_admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerInitialized {
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[embeddable_as(Admin)]
    impl AdminImpl<TContractState, +HasComponent<TContractState>> of IAdmin<ComponentState<TContractState>> {

        fn get_admin(self: @ComponentState<TContractState>) -> ContractAddress {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, Errors::NOT_OWNER);
            self.admin.read()
        }

        fn set_admin(ref self: ComponentState<TContractState>, new_admin: ContractAddress) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, Errors::NOT_OWNER);
            self.admin.write(new_admin);

            self.emit(Event::AdminSet { new_admin });
        }

        fn renounce_admin(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            let previous_admin = self.admin.read();
            assert(caller == owner, Errors::NOT_OWNER);
            self.admin.write(Zero::zero());

            self.emit(Event::AdminRenounced { previous_admin });
        }
    }

    #[generate_trait]
    pub impl PrivateImpl<TContractState, +HasComponent<TContractState>> of PrivateTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);

            self.emit(Event::OwnershipInitialized { new_owner: owner });
        }

        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, Errors::NOT_OWNER);
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_OWNER);
        }

        fn _transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            let previous_owner = self.owner.read();
            self.owner.write(new_owner);

            self.emit(Event::OwnershipTransferred { previous_owner, new_owner });
        }
    }
}