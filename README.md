## PIV Pairing Scripts

These scripts can associate a user with a PIV smart card by different pairing methods.

### Prerequisite

- Install [piv-cli-tool](https://github.com/AuthenTrend/piv-cli-tool)
- Install [swiftDialog](https://github.com/swiftDialog/swiftDialog)

### Pairing Methods

#### Lookup Table

To pair the current user with a PIV smart card that can be found in ```MAPPING_TABLE``` in ```src/lookup_table/mapping-table.sh```.

Each line in ```MAPPING_TABLE``` is a user-PIV pair, the format is as follows.
```
"USER:CHUID:HASH"
```
* ```USER``` is user account name
* ```CHUID``` is cardholder unique identifier. which can be known by running command ```piv-cli-tool -r READER -a status``` or ```piv-cli-tool -r READER -a read-object --id=0x5FC102```.
* ```HASH``` is public key hash of a certificate, this is optional. Specifying hash to specify the pairing certificate. Hashes can be known by running command ```sc_auth identities```.

Examples:
```
"joshua:3019d4e739da739ced39ce739d836858210842108421c84210c3eb341018d0e48becd1f91b91f845089e9b3e13350832303330303130313e00fe00"
"user1:3019d4e739da739ced39ce739d836858210842108421c84210c3eb341018d0e48becd1f91b91f845089e9b3e13350832303330303130313e00fe00:B549D7112F6762C1C917F0947C401DC98CEE2CEA"
```

### Usage

- Unpairing all paired PIV smart cards
```
./piv-pairing.sh unpair
```

- Pairing with the lookup table method
```
sudo ./piv-pairing.sh pair lookup_table
```

### Using in Jamf Pro

Jamf Pro can create scripts via ```Settings > Computer management > Scripts``` , and can add packages via ```Settings > Computer management > Packages``` .

In order to use these scripts in Jamf Pro's Self Service, you need to create a script named ```piv-pairing.sh``` to include the entire contents of ```src/piv-pairing.sh``` .  
At the top of the script, ```JAMF_PRO_MODE=0``` needs to be changed to 1.

Both packages [piv-cli-tool](https://github.com/AuthenTrend/piv-cli-tool) and [swiftDialog](https://github.com/swiftDialog/swiftDialog) need to be added for installing on user's computer.

For using different pairing methods, more details are described as follows.

#### Lookup Table

- Create a script named ```mapping-table.sh``` to include the entire contents of ```src/lookup_table/mapping-table.sh``` .
- Copy the entire contents of ```src/lookup_table/pairing-form-table.sh``` except the first line, and paste it into the bottom of function ```pairing_from_table()``` in ```piv-pairing.sh``` , then comment out the lines that starting with ```source``` in the function.

#### Policies / Self Service

  In order to make a script function to be displayed as a button in Self Service, you need to create a policy and enable it available in Self Service via ```Settings > Computers > Policies```.

###### - Create a button for unpairing PIV
- Create a new policy
- Set ```Execution Frequency``` to ```Ongoing``` in ```Options > General```
- Add necessary packages in ```Options > Packages```
- Add ```piv-pairing.sh``` and set ```Parameter 4``` to ```unpair``` in ```Options > Scripts```
- Set scope to ```All Computers``` and ```All Users``` in ```Scope > Targets```
- Check ```Make the policy available in Self Service``` in ```Self Service```

###### - Create a button for pairing PIV by lookup table
- Create a new policy
- Set ```Execution Frequency``` to ```Ongoing``` in ```Options > General```
- Add necessary packages in ```Options > Packages```
- Add ```piv-pairing.sh```, set ```Parameter 4``` to ```pair``` and ```Parameter 5``` to ```lookup_table``` in ```Options > Scripts```
- Add ```mapping-table.sh```, change ```Priority``` to ```Before``` and set ```Parameter 4``` to ```dump``` in ```Options > Scripts```
- Set scope to ```All Computers``` and ```All Users``` in ```Scope > Targets```
- Check ```Make the policy available in Self Service``` in ```Self Service```
