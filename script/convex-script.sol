pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CreditAccount} from "core-v2/credit/CreditAccount.sol";
import {CreditManager} from "core-v2/credit/CreditManager.sol";
import {CreditFacade} from "core-v2/credit/CreditFacade.sol";
import {MultiCall} from "core-v2/libraries/MultiCall.sol";
import {RAY} from "core-v2/libraries/Constants.sol";
import {IERC20Metadata} from "core-v2/interfaces/IPhantomERC20.sol";

import {ConvexV1BaseRewardPoolAdapter} from "integrations-v2/contracts/adapters/convex/ConvexV1_BaseRewardPool.sol";
import {ConvexV1BoosterAdapter} from "integrations-v2/contracts/adapters/convex/ConvexV1_Booster.sol";
import {CurveV1AdapterStETH} from "integrations-v2/contracts/adapters/curve/CurveV1_stETH.sol";

ConvexV1BaseRewardPoolAdapter constant steCRVRewardPool =
    ConvexV1BaseRewardPoolAdapter(0xeBE13b1874bB2913CB3F04d4231837867ff77999);
ConvexV1BoosterAdapter constant booster = ConvexV1BoosterAdapter(0xD5533F3C02D2b96d040206cCC51CeB0Eb70A7ce4);
CurveV1AdapterStETH constant steCRV = CurveV1AdapterStETH(0x0Ad2Fc10F677b2554553DaF80312A98ddb38f8Ef);
IERC20Metadata constant stETH = IERC20Metadata(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
uint256 constant steCRV_PID = 25;

contract ConvexScript is Script {
    function withdrawConvexPositioToStETH(CreditAccount _account) external {
        CreditManager manager = CreditManager(_account.creditManager());
        CreditFacade facade = CreditFacade(manager.creditFacade());

        MultiCall[] memory multicall = new MultiCall[](3);

        // withdraw and claim from reward pool
        multicall[0] = MultiCall({
            target: address(steCRVRewardPool),
            callData: abi.encodeWithSelector(steCRVRewardPool.withdrawAll.selector, (true))
        });

        // get current exchange rate
        uint256 balance = steCRVRewardPool.balanceOf(address(_account));
        uint256 stETHOut = steCRV.calc_withdraw_one_coin(balance, 1);
        uint256 minRayOut = (stETHOut * RAY / balance) * 99 / 100; // 1% slippage

        // withdraw from convex reward pool
        multicall[1] = MultiCall({
            target: address(booster),
            callData: abi.encodeWithSelector(booster.withdrawAll.selector, steCRV_PID)
        });

        // withdraw from convex booster
        multicall[2] = MultiCall({
            // target: address(ste)
            target: address(steCRV),
            callData: abi.encodeWithSelector(steCRV.remove_all_liquidity_one_coin.selector, int128(1), minRayOut)
        });

        uint256 stETHBalanceBefore = stETH.balanceOf(address(_account));
        vm.broadcast();
        facade.multicall(multicall);

        uint256 stETHBalanceAfter = stETH.balanceOf(address(_account));
        console.log(stETHBalanceBefore);
        console.log(stETHBalanceAfter);
    }
}
