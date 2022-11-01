//
//  EthViewController.swift
//  MagicSDK_Example
//
//  Created by Jerry Liu on 5/23/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import MagicSDK_Web3
import MagicSDK
#if canImport(Web3ContractABI)
import Web3ContractABI
#endif
#if canImport(Web3PromiseKit)
import Web3PromiseKit
#endif


protocol Web3ViewControllerDelegate: AnyObject {}

class Web3ViewController: UIViewController {
    
    static let storyboardIdentifier = "web3"
        
        enum Error: Swift.Error {
            case noAccountsFound
        }
        
        weak var delegate: Web3ViewControllerDelegate?
    
    var rpcProvider: RpcProvider {
        if Magic.shared != nil {
            return Magic.shared.rpcProvider
        }
            return MagicConnect.shared.rpcProvider
    }
        
        /// Instance
        var web3 = Web3(provider: Magic.shared != nil ? Magic.shared.rpcProvider : MagicConnect.shared.rpcProvider)
//        var web3 = Web3(provider: MagicConnect.shared.rpcProvider)
        
        /// Vars
        var account: EthereumAddress?
        var balance: EthereumQuantity?
    
        var contract: DynamicContract?
        let contractAbi = """
    [{"constant":false,"inputs":[{"name":"newMessage","type":"string"}],"name":"update","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"message","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"initMessage","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"}]
    """.data(using: .utf8)!
        
        /// UI
        @IBOutlet weak var balanceLabel: UILabel!
        @IBOutlet weak var accountLabel: UILabel!

        override func viewDidLoad() {
            super.viewDidLoad()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            if self.account == nil {
                updateAccounts()
            }
            super.viewDidAppear(animated)
        }
        
        func updateAccounts() {
            
            firstly {
                web3.eth.accounts()
            }.done { accounts -> Void in
                if let account = accounts.first {
    
                    self.account = account
                    self.accountLabel.text = account.hex(eip55: false)
                    print(self.accountLabel.text)
                } else {
                    throw Error.noAccountsFound
                }
            }.catch { error in
                self.showResult("Error loading accounts and balance: \(error)")
            }
        }

    
    func testGetBalance() {
        
        firstly {
            web3.eth.getBalance(address: account!, block: .latest)
        }.done { balance -> Void in

            self.showResult(String(balance.hashValue))
        }.catch { error in
            self.showResult("Error loading balance: \(error)")
        }
    }
        
        
        // MARK: - web3 functions
        func sendTestTransaction() {
            
            // Construct transaction
                let transaction = EthereumTransaction(from: account ?? EthereumAddress(hexString: "0xc34b1486b43454faada7cf250b6cda0e514170b4"), to: EthereumAddress(hexString: "0xc34b1486b43454faada7cf250b6cda0e514170b4"), value:EthereumQuantity(quantity: BigUInt(1)))
//                web3.eth.sendTransaction(transaction: transaction).done { (transactionHash) in
//                    self.showResult(transactionHash.hex())
//                }.catch { error in
//                    self.showResult(error.localizedDescription)
//                }
            web3.eth.sendTransaction(transaction: transaction) { ( response: Web3Response<EthereumData>) in
//                self.showResult(response.result?.hex)
                self.showResult(response.error.debugDescription)
            }
        }
        
        func testGetCoinbase() {
            
            web3.eth.getCoinbase().done({ response in
                self.showResult(response.hex(eip55: false))
            })
        }
    
    func testNetworkId() {
        
        web3.net.version().done({ response in
            self.showResult(response)
        })
    }
        
        /// personal sign
        func testPersonalSign() {
        
            guard let address = account else { return }
            let message = try! EthereumData("Hello World".data(using: .utf8)!)
            let request = RPCRequest<EthereumValue>(id: 2, jsonrpc: "2.0", method: "personal_sign", params: [message, address])
            web3.provider.send(request: request) { ( response: Web3Response<EthereumValue>) in
                self.showResult(response.result?.string ?? "")
            }
        }
        
        /// eth sign
        func testSign() {
        
            guard let address = account else { return }
            let message = try! EthereumData("Hello World".data(using: .utf8)!)
            web3.eth.sign(from: address, message: message).done({response in
                self.showResult(response.hex())
            })
        }
        
        /// signTypedData
        func testSignTypedDataLegacy() {

            guard let address = account else { return }
            let payload = EIP712TypedDataLegacyFields(type: "string", name: "Hello from Magic Labs", value: "This message will be signed by you")

            web3.eth.signTypedDataLegacy(account: address, data: [payload]).done({ response in
                self.showResult(response.hex())
            })
        }
        
        
        func testSignTypedDataV3() {
            
            guard let address = account else { return }
            
            do {
                let json = """
                {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"verifyingContract","type":"address"}],"Order":[{"name":"makerAddress","type":"address"},{"name":"takerAddress","type":"address"},{"name":"feeRecipientAddress","type":"address"},{"name":"senderAddress","type":"address"},{"name":"makerAssetAmount","type":"uint256"},{"name":"takerAssetAmount","type":"uint256"},{"name":"makerFee","type":"uint256"},{"name":"takerFee","type":"uint256"},{"name":"expirationTimeSeconds","type":"uint256"},{"name":"salt","type":"uint256"},{"name":"makerAssetData","type":"bytes"},{"name":"takerAssetData","type":"bytes"}]},"domain":{"name":"0x Protocol","version":"2","verifyingContract":"0x35dd2932454449b14cee11a94d3674a936d5d7b2"},"message":{"exchangeAddress":"0x35dd2932454449b14cee11a94d3674a936d5d7b2","senderAddress":"0x0000000000000000000000000000000000000000","makerAddress":"0x338be8514c1397e8f3806054e088b2daf1071fcd","takerAddress":"0x0000000000000000000000000000000000000000","makerFee":"0","takerFee":"0","makerAssetAmount":"97500000000000","takerAssetAmount":"15000000000000000","makerAssetData":"0xf47261b0000000000000000000000000d0a1e359811322d97991e03f863a0c30c2cf029c","takerAssetData":"0xf47261b00000000000000000000000006ff6c0ff1d68b964901f986d4c9fa3ac68346570","salt":"1553722433685","feeRecipientAddress":"0xa258b39954cef5cb142fd567a46cddb31a670124","expirationTimeSeconds":"1553808833"},"primaryType":"Order"}
                """.data(using: .utf8)!
                let typedDataV3 = try JSONDecoder().decode(EIP712TypedData.self, from: json)
                
                web3.eth.signTypedData(account: address, data: typedDataV3).done({ response in
                    self.showResult(response.hex())
                })
            } catch {
                self.showResult(error.localizedDescription)
            }
        }
    
    func testSignTypedDataV4() {
        
        guard let address = account else { return }
        
        do {
            let json = """
            {"domain":{"chainId":1,"name":"Ether Mail","verifyingContract":"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC","version":"1"},"message":{"contents":"Hello, Bob!","from":{"name":"Cow","wallets":["0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826","0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF"]},"to":[{"name":"Bob","wallets":["0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB","0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57","0xB0B0b0b0b0b0B000000000000000000000000000"]}]},"primaryType":"Mail","types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Group":[{"name":"name","type":"string"},{"name":"members","type":"Person[]"}],"Mail":[{"name":"from","type":"Person"},{"name":"to","type":"Person[]"},{"name":"contents","type":"string"}],"Person":[{"name":"name","type":"string"},{"name":"wallets","type":"address[]"}]}}
            """
            let typedData = json.data(using: .utf8)!
            let typedDataV4 = try JSONDecoder().decode(EIP712TypedData.self, from: typedData)
            web3.eth.signTypedDataV4(account: address, data: typedDataV4).done({ response in
                print(response.hex())
                self.showResult(response.hex())
            })
            
 

        } catch let DecodingError.typeMismatch(type, context)  {
               print("Type '\(type)' mismatch:", context.debugDescription)
               print("codingPath:", context.codingPath)
        } catch {
            self.showResult(error.localizedDescription)
        }
    }
        
        func testGetNetwork() {
            
            firstly {
                web3.net.version()
            }.done { version in
                self.showResult(version)
            }.catch { error in
                self.showResult(error.localizedDescription)
            }
        }

        
        // MARK: - contracts
        func testDeployContract() {
            guard let account = self.account else { return }
            
            do {
                
                    //Replace your deployed address here
                let contract = try web3.eth.Contract(json: self.contractAbi, abiKey: nil, address: nil)
                self.contract = contract
                let byteCode = try EthereumData(ethereumValue: "0x608060405234801561001057600080fd5b5060405161047f38038061047f8339818101604052602081101561003357600080fd5b81019080805164010000000081111561004b57600080fd5b8281019050602081018481111561006157600080fd5b815185600182028301116401000000008211171561007e57600080fd5b5050929190505050806000908051906020019061009c9291906100a3565b5050610148565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106100e457805160ff1916838001178555610112565b82800160010185558215610112579182015b828111156101115782518255916020019190600101906100f6565b5b50905061011f9190610123565b5090565b61014591905b80821115610141576000816000905550600101610129565b5090565b90565b610328806101576000396000f3fe608060405234801561001057600080fd5b5060043610610053576000357c0100000000000000000000000000000000000000000000000000000000900480633d7403a314610058578063e21f37ce14610113575b600080fd5b6101116004803603602081101561006e57600080fd5b810190808035906020019064010000000081111561008b57600080fd5b82018360208201111561009d57600080fd5b803590602001918460018302840111640100000000831117156100bf57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610196565b005b61011b6101b0565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561015b578082015181840152602081019050610140565b50505050905090810190601f1680156101885780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b80600090805190602001906101ac92919061024e565b5050565b60008054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156102465780601f1061021b57610100808354040283529160200191610246565b820191906000526020600020905b81548152906001019060200180831161022957829003601f168201915b505050505081565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061028f57805160ff19168380011785556102bd565b828001600101855582156102bd579182015b828111156102bc5782518255916020019190600101906102a1565b5b5090506102ca91906102ce565b5090565b6102f091905b808211156102ec5760008160009055506001016102d4565b5090565b9056fea265627a7a7230582003ae1ef5a63bf058bfd2b31398bdee39d3cbfbb7fbf84235f4bc2ec352ee810f64736f6c634300050a0032")
                    
                guard let invocation = contract.deploy(byteCode: byteCode) else { return }
                /// Deploy contract
                invocation.send(from: account, gas: 1025256, gasPrice: 0) { (hash, error) in
                    self.showResult(hash?.hex() ?? "")
                    self.showResult(error?.localizedDescription ?? "")
                    }

            } catch {
                print("Contract error")
                self.showResult(error.localizedDescription)
            }
        }
        
        func testContractCallRead () {
            
            do {
                
                let contract = try web3.eth.Contract(json: self.contractAbi, abiKey: nil, address: EthereumAddress(ethereumValue: "0x8b211dfebf490a648f6de859dfbed61fa22f35e0"))
                
                contract["message"]?().call() { response, error in
                    if let response = response, let message = response[""] as? String {
                        self.showResult(message.description)
                    } else {
                        self.showResult(error?.localizedDescription ?? "")
                    }
                }
            } catch {
                self.showResult(error.localizedDescription)
            }
        }
    
        func testContractCallWrite () {

            guard let account = self.account else { return }
            
            do {

                let contract = try web3.eth.Contract(json: self.contractAbi, abiKey: nil, address: EthereumAddress(ethereumValue: "0x8b211dfebf490a648f6de859dfbed61fa22f35e0"))
                
                guard let transaction = contract["update"]?("NEW_MESSAGE").createTransaction(nonce: 0, from: account, value: 0, gas: EthereumQuantity(150000), gasPrice: EthereumQuantity(quantity: 21.gwei)) else { return }
                
                web3.eth.sendTransaction(transaction: transaction).done({ txHash in
                    self.showResult(txHash.hex())
                }).catch{ error in
                    self.showResult(error.localizedDescription)
                }
            
            } catch {
                self.showResult(error.localizedDescription)
            }
        }
    
        
        
        
        // MARK: - buttons
        
        @IBAction func getCoinbase() {
            testGetCoinbase()
        }
        
        @IBAction func getBalance() {
            testGetBalance()
        }
    
        @IBAction func sendTransaction() {
            sendTestTransaction()
        }
        
        @IBAction func getNetwork() {
            testGetNetwork()
        }
        
        @IBAction func personalSign() {
            testPersonalSign()
        }
        
        @IBAction func sign() {
            testSign()
        }
        
        @IBAction func signTypedDataV1() {
            testSignTypedDataLegacy()
        }

        @IBAction func signTypedDataV3() {
            testSignTypedDataV3()
        }
    
    @IBAction func signTypedDataV4() {
        testSignTypedDataV4()
    }
    
        
        @IBAction func deployContract() {
            testDeployContract()
        }
        
        @IBAction func contractCallRead() {
            testContractCallRead()
        }
    
    @IBAction func contractCallwrite() {
        testContractCallWrite()
    }
}
