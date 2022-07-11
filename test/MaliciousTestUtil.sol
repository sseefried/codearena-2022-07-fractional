// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import {Blacksmith} from "./blacksmith/Blacksmith.sol";
import {BaseVault, BaseVaultBS} from "./blacksmith/BaseVault.bs.sol";
import {Buyout, BuyoutBS} from "./blacksmith/Buyout.bs.sol";
import {FERC1155, FERC1155BS} from "./blacksmith/FERC1155.bs.sol";
import {Metadata, MetadataBS} from "./blacksmith/Metadata.bs.sol";
import {Migration, MigrationBS} from "./blacksmith/Migration.bs.sol";
import {MaliciousMod, MaliciousModBS} from "./blacksmith/MaliciousMod.bs.sol";
import {Minter} from "../src/modules/Minter.sol";
import {MockModule} from "../src/mocks/MockModule.sol";
import {MockERC20, MockERC20BS} from "./blacksmith/MockERC20.bs.sol";
import {MockERC721, MockERC721BS} from "./blacksmith/MockERC721.bs.sol";
import {MockERC1155, MockERC1155BS} from "./blacksmith/MockERC1155.bs.sol";
import {NFTReceiver} from "../src/utils/NFTReceiver.sol";
import {Supply, SupplyBS} from "./blacksmith/Supply.bs.sol";
import {Malicious, MaliciousBS} from "./blacksmith/Malicious.bs.sol";
import {Transfer, TransferBS} from "./blacksmith/Transfer.bs.sol";
import {TransferReference} from "../src/references/TransferReference.sol";
import {Vault, VaultBS} from "./blacksmith/Vault.bs.sol";
import {VaultFactory, VaultFactoryBS} from "./blacksmith/VaultFactory.bs.sol";
import {VaultRegistry, VaultRegistryBS} from "./blacksmith/VaultRegistry.bs.sol";
import {WETH} from "@rari-capital/solmate/src/tokens/WETH.sol";

import {IBuyout, State} from "../src/interfaces/IBuyout.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IERC721} from "../src/interfaces/IERC721.sol";
import {IERC1155} from "../src/interfaces/IERC1155.sol";
import {IFERC1155} from "../src/interfaces/IFERC1155.sol";
import {IMigration} from "../src/interfaces/IMigration.sol";
import {IModule} from "../src/interfaces/IModule.sol";
import {IVault} from "../src/interfaces/IVault.sol";
import {IVaultFactory} from "../src/interfaces/IVaultFactory.sol";
import {IVaultRegistry} from "../src/interfaces/IVaultRegistry.sol";

import "../src/constants/Permit.sol";

contract MaliciousTestUtil is Test {
    BaseVault baseVault;
    Buyout buyoutModule;
    Metadata metadata;
    Migration migrationModule;
    MaliciousMod maliciousModule;
    Minter minter;
    MockModule mockModule;
    NFTReceiver receiver;
    Supply supplyTarget;
    Malicious maliciousTarget;
    Transfer transferTarget;
    Vault vaultProxy;
    VaultRegistry registry;
    WETH weth;

    FERC1155BS fERC1155;

    struct User {
        address addr;
        uint256 pkey;
        Blacksmith base;
        BaseVaultBS baseVault;
        BuyoutBS buyoutModule;
        MigrationBS migrationModule;
        MaliciousModBS maliciousModule;
        MockERC721BS erc721;
        MockERC1155BS erc1155;
        MockERC20BS erc20;
        TransferBS transfer;
        VaultRegistryBS registry;
        FERC1155BS ferc1155;
        VaultBS vaultProxy;
    }

    User alice;
    User bob;
    User eve;
    address buyout;
    address erc20;
    address erc721;
    address erc1155;
    address factory;
    address migration;
    address token;
    address vault;
    bool approved;
    uint256 deadline;
    uint256 nonce;
    uint256 proposalPeriod;
    uint256 rejectionPeriod;
    uint256 tokenId;

    address[] modules = new address[](2);

    bytes32 merkleRoot;
    bytes32[] merkleTree;
    bytes32[] hashes;
    bytes32[] mintProof = new bytes32[](3);
    bytes32[] setIndexProof = new bytes32[](3);

    bytes4[] nftReceiverSelectors = new bytes4[](0);
    address[] nftReceiverPlugins = new address[](0);

    uint256 constant INITIAL_BALANCE = 100 ether;
    uint256 constant TOTAL_SUPPLY = 10000;
    uint256 constant HALF_SUPPLY = TOTAL_SUPPLY / 2;
    address constant WETH_ADDRESS =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// =================
    /// ===== USERS =====
    /// =================
    function createUser(address _addr, uint256 _privateKey)
        public
        returns (User memory)
    {
        Blacksmith base = new Blacksmith(_addr, _privateKey);
        BaseVaultBS _minter = new BaseVaultBS(
            _addr,
            _privateKey,
            address(baseVault)
        );
        BuyoutBS _buyout = new BuyoutBS(
            _addr,
            _privateKey,
            address(buyoutModule)
        );
        MigrationBS _migration = new MigrationBS(
            _addr,
            _privateKey,
            address(migrationModule)
        );
        MaliciousModBS _malicious = new MaliciousModBS(
          _addr,
          _privateKey,
          address(maliciousModule)
        );
        MockERC721BS _erc721 = new MockERC721BS(
            _addr,
            _privateKey,
            address(erc721)
        );
        MockERC1155BS _erc1155 = new MockERC1155BS(
            _addr,
            _privateKey,
            address(erc1155)
        );
        MockERC20BS _erc20 = new MockERC20BS(
            _addr,
            _privateKey,
            address(erc20)
        );
        TransferBS _transfer = new TransferBS(
            _addr,
            _privateKey,
            address(transferTarget)
        );
        VaultRegistryBS _registry = new VaultRegistryBS(
            _addr,
            _privateKey,
            address(registry)
        );
        FERC1155BS _ferc1155 = new FERC1155BS(_addr, _privateKey, address(0));
        VaultBS _proxy = new VaultBS(_addr, _privateKey, address(0));
        base.deal(INITIAL_BALANCE);
        return
            User(
                base.addr(),
                base.pkey(),
                base,
                _minter,
                _buyout,
                _migration,
                _malicious,
                _erc721,
                _erc1155,
                _erc20,
                _transfer,
                _registry,
                _ferc1155,
                _proxy
            );
    }

    /// ==================
    /// ===== SETUPS =====
    /// ==================
    function setUpContract() public {
        registry = new VaultRegistry();
        supplyTarget = new Supply(address(registry));
        maliciousTarget = new Malicious();
        minter = new Minter(address(supplyTarget));
        transferTarget = new Transfer();
        receiver = new NFTReceiver();
        buyoutModule = new Buyout(
            address(registry),
            address(supplyTarget),
            address(transferTarget)
        );
        migrationModule = new Migration(
            address(buyoutModule),
            address(registry),
            address(supplyTarget)
        );
        maliciousModule = new MaliciousMod(address(maliciousTarget));
        baseVault = new BaseVault(address(registry), address(supplyTarget));
        erc20 = address(new MockERC20());
        erc721 = address(new MockERC721());
        erc1155 = address(new MockERC1155());

        vm.label(address(registry), "VaultRegistry");
        vm.label(address(supplyTarget), "SupplyTarget");
        vm.label(address(maliciousTarget), "MaliciousTarget");
        vm.label(address(transferTarget), "TransferTarget");
        vm.label(address(baseVault), "BaseVault");
        vm.label(address(buyoutModule), "BuyoutModule");
        vm.label(address(migrationModule), "MigrationModule");
        vm.label(address(maliciousModule), "MaliciousModule");
        vm.label(address(erc20), "ERC20");
        vm.label(address(erc721), "ERC721");
        vm.label(address(erc1155), "ERC1155");

        setUpWETH();
        setUpProof();
    }

    function setUpWETH() public {
        WETH _weth = new WETH();
        bytes memory code = address(_weth).code;
        vm.etch(WETH_ADDRESS, code);
        weth = WETH(payable(WETH_ADDRESS));

        vm.label(WETH_ADDRESS, "WETH");
    }

    function setUpProof() public {
        modules[0] = address(baseVault);
        modules[1] = address(maliciousModule);

        hashes = new bytes32[](2);
        hashes[0] = baseVault.getLeafNodes()[0];
        hashes[1] = maliciousModule.getLeafNodes()[0];

        assert(baseVault.getLeafNodes().length == 1);
        assert(maliciousModule.getLeafNodes().length == 1);

        merkleTree    = baseVault.generateMerkleTree(modules);
        assert(merkleTree.length == 6); // WEIRD!

        merkleRoot    = baseVault.getRoot(merkleTree);
        mintProof     = baseVault.getProof(hashes, 0);
        setIndexProof = baseVault.getProof(hashes, 1);
    }

    function setUpUser(uint256 _privateKey, uint256 _tokenId)
        public
        returns (User memory user)
    {
        user = createUser(address(0), _privateKey);
        MockERC721(erc721).mint(user.addr, _tokenId);
    }

    /// ======================
    /// ===== BASE VAULT =====
    /// ======================
    function deployBaseVault(User memory _user, uint256 _fractions) public {
        vault = _user.baseVault.deployVault(
            _fractions,
            modules,
            nftReceiverPlugins,
            nftReceiverSelectors,
            mintProof
        );
        _user.erc721.safeTransferFrom(_user.addr, vault, 1);
        vm.label(vault, "VaultProxy");
    }


    function setUpMalicious(
        User memory _user1
    ) public {
        deployBaseVault(_user1, 10000000);
        vm.label(vault, "VaultProxy");
    }



    /// ===========================
    /// ===== MIGRATION ===========
    /// ===========================
    function setUpMigration(
        User memory _user1,
        User memory _user2,
        uint256 _fractions
    ) public {
        deployBaseVault(_user1, _fractions);
        (token, tokenId) = registry.vaultToToken(vault);
        _user1.ferc1155 = new FERC1155BS(address(0), 111, token);
        _user2.ferc1155 = new FERC1155BS(address(0), 222, token);

        mockModule = new MockModule();
        buyout = address(buyoutModule);
        migration = address(migrationModule);
        proposalPeriod = buyoutModule.PROPOSAL_PERIOD();
        rejectionPeriod = buyoutModule.REJECTION_PERIOD();

        vm.label(vault, "VaultProxy");
        vm.label(token, "Token");
    }

    /// ===========================
    /// ===== INITIALIZATIONS =====
    /// ===========================
    function initializeDeploy() public view returns (bytes memory deployVault) {
        deployVault = abi.encodeCall(
            baseVault.deployVault,
            (
                TOTAL_SUPPLY,
                modules,
                nftReceiverPlugins,
                nftReceiverSelectors,
                mintProof
            )
        );
    }
    function initializeMalicious(
        User memory _user1
    ) public {
        setUpMalicious(_user1);
    }

}
