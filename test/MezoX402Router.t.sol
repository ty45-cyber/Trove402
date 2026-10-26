// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {MezoCreditVault} from "../contracts/MezoCreditVault.sol";
import {X402SettlementRouter} from "../contracts/X402SettlementRouter.sol";
import {X402Invoice, DailySpendLimitExceeded} from "../contracts/interfaces/IMezoCore.sol";

contract MockMUSDAndPrice {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function fetchPrice() external pure returns (uint256) {
        return 100_000e18; // $100,000 per BTC
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[to] += amount;
        return true;
    }
}

contract MockMezoPools {
    MockMUSDAndPrice public immutable token;

    constructor(address _token) {
        token = MockMUSDAndPrice(_token);
    }

    function openTrove(uint256 debtAmount, address, address) external payable {
        token.transfer(msg.sender, debtAmount);
    }

    function provideToSP(uint256) external pure {}
}

contract MockStabilityWithdraw {
    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function withdrawFromSP(uint256) external pure {}
}

contract MezoX402RouterTest {
    MezoCreditVault public vault;
    X402SettlementRouter public router;
    MockMUSDAndPrice public mockCore;

    address public constant AGENT_EOA = address(0xA6E47);
    address public constant MERCHANT_EOA = address(0xB17E);

    function setUp() public {
        mockCore = new MockMUSDAndPrice();
        // Predict deterministic router deployment address or deploy router pointing to vault
        uint256 nonce = 2; // Next contract slot
        address predictedVault = computeCreateAddress(address(this), nonce + 1);
        router = new X402SettlementRouter(predictedVault);
        vault = new MezoCreditVault(
            address(mockCore),
            address(mockCore),
            address(new MockMezoPools(address(mockCore))),
            address(new MockStabilityWithdraw()),
            address(router)
        );
    }

    function computeCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        bytes memory data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce));
        return address(uint160(uint256(keccak256(data))));
    }
}