# gearbox-CA-scripts

Some scripted interactions I have used for my credit account.
Demonstrates how one can use forge scripting to script the credit account multicalls.

## Install

```bash
forge install
cd lib/core-v2; yarn // gearbox uses openzeppelin, need to get their source from npm
cd lib/integrations-v2; yarn // gearbox uses openzeppelin, need to get their source from npm
```

## Write a script

```solidity
contract InteractionScript is Script {
    function interaction(address _creditAccount) external {
        MultiCall[] memory multicalls = new MultiCall[](3);
        multicalls[0] = MultiCall({
            target: "", // adapter address
            abi.encodeWithSelector(Adapter.method.selector, ...) // encoding calldata
        });

        facade.multicall(multicalls);
    }
}
```

## Run a script

```bash
forge script ./script/script-file.sol --sig "interaction(address)" <CREDIT_ACCOUNT> --rpc-url https://eth.llamarpc.com --broadcast -vvvv --private-key <PRIVATE_KEY>
```

This will run the script against local fork, sign the tx and send it.
Remove the `--broadcast` option if you dont want to broadcast.
