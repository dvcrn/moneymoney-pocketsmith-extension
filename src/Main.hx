import lua.Table;
import Pocketsmith;
import Storage;

enum abstract AccountType(String) {
    var AccountTypeGiro = "AccountTypeGiro" ;
    var AccountTypeSavings = "AccountTypeSavings" ;
    var AccountTypeFixedTermDeposit = "AccountTypeFixedTermDeposit" ;
    var AccountTypeLoan = "AccountTypeLoan" ;
    var AccountTypeCreditCard = "AccountTypeCreditCard" ;
    var AccountTypePortfolio = "AccountTypePortfolio" ;
    var AccountTypeOther = "AccountTypeOther" ;
}

typedef Account = {
    ?name:String,
    ?owner:String,
    ?accountNumber:String,
    ?subAccount:String,
    ?portfolio:Bool,
    ?bankCode:String,
    ?currency:String,
    ?iban:String,
    ?bic:String,
    ?balance:Float,
    type:AccountType
}

typedef Transaction = {
    ?name:String,
    ?accountNumber:String,
    ?bankCode:String,
    ?amount:Float,
    ?currency:String,
    ?bookingDate:Int,
    ?valueDate:Int,
    ?purpose:String,
    ?transactionCode:Int,
    ?textKeyExtension:Int,
    ?purposeCode:String,
    ?bookingKey:String,
    ?bookingText:String,
    ?primanotaNumber:String,
    ?batchReference:String,
    ?endToEndReference:String,
    ?mandateReference:String,
    ?creditorId:String,
    ?returnReason:String,
    ?booked:Bool
}

typedef Security = {
    ?name:String,
    ?isin:String,
    ?securityNumber:String,
    ?quantity:Float,
    ?currencyOfQuantity:String,
    ?purchasePrice:Float,
    ?currencyOfPurchasePrice:String,
    ?exchangeRateOfPurchasePrice:Float,
    ?price:Float,
    ?currencyOfPrice:String,
    ?exchangeRateOfPrice:Float,
    ?amount:Float,
    ?originalAmount:Float,
    ?currencyOfOriginalAmount:String,
    ?market:String,
    ?tradeTimestamp:Int
}

class Main {
    static function psTypeToAccountType(psType:TransactionAccountType):AccountType {
        return switch (psType) {
            case TransactionAccountType.Bank: AccountType.AccountTypeGiro;
            case TransactionAccountType.Credits: AccountType.AccountTypeCreditCard;
            case TransactionAccountType.Stocks: AccountType.AccountTypePortfolio;
            case TransactionAccountType.Mortgage: AccountType.AccountTypeOther;
            case TransactionAccountType.Loans: AccountType.AccountTypeLoan;
            case TransactionAccountType.Vehicle: AccountType.AccountTypeOther;
            case TransactionAccountType.Property: AccountType.AccountTypeOther;
            case TransactionAccountType.Insurance: AccountType.AccountTypeOther;
            case TransactionAccountType.OtherAsset: AccountType.AccountTypeOther;
            case TransactionAccountType.OtherLiability: AccountType.AccountTypeOther;
            default: AccountType.AccountTypeOther;
        }
    }

    @:luaDotMethod
    @:expose("SupportsBank")
    static function SupportsBank(protocol:String, bankCode:String) {
        trace("SupportsBank got called");
        trace(protocol);
        trace(bankCode);

        return bankCode == "Pocketsmith";
    }

    @:luaDotMethod
    @:expose("InitializeSession")
    static function InitializeSession(protocol:String, bankCode:String, username:String, reserved, password:String) {
        trace("InitializeSession got called");
        trace(protocol);
        trace(bankCode);
        trace(username);
        trace(reserved);
        trace(password);

        var user = Pocketsmith.getCurrentUser(password);
        trace(user);
        trace(user.name);

        Storage.set("username", username);
        Storage.set("user_id", user.id);
        Storage.set("api_key", password);
    }

    @:luaDotMethod
    @:expose("ListAccounts")
    static function ListAccounts(knownAccounts) {
        trace("ListAccounts got called");
        trace(knownAccounts);

        var userId = Storage.get("user_id");
        var apiKey = Storage.get("api_key");
        trace(userId);

        var accounts = Pocketsmith.getTransactionAccounts(apiKey, userId);
        trace("got accounts back:");
        trace(accounts);

        var accountObjs = [];
        for (account in accounts) {
            var accountObj:Account = {
                name: account.name + " (" + account.institution.title + ")",
                accountNumber: Std.string(account.id),
                currency: account.currency_code,
                balance: account.current_balance,
                type: psTypeToAccountType(account.type),
                iban: account.number,
            };
            accountObjs.push(accountObj);
        }

        var results = Table.fromArray(accountObjs);

        trace(results);

        return results;
    }

    @:luaDotMethod
    @:expose("RefreshAccount")
    static function RefreshAccount(account:{
        iban:String,
        bic:String,
        comment:String,
        bankCode:String,
        owner:String,
        attributes:Dynamic,
        subAccount:String,
        currency:String,
        name:String,
        balance:Float,
        portfolio:Bool,
        type:String,
        balanceDate:Float,
        accountNumber:String
    }, since:Float) {
        trace("RefreshAccount got called");
        trace(account);
        trace("account number: " + account.accountNumber);
        trace("IBAN: " + account.iban);
        trace(since);

        var userId = Storage.get("user_id");
        var date = Date.fromTime(since * 1000);
        var apiKey = Storage.get("api_key");

        trace(userId);

        // conver to ISO8601
        var sinceStr = DateTools.format(date, "%Y-%m-%dT%H:%M:%S");
        trace(sinceStr);

        var accountNumberStr = Std.parseInt(account.accountNumber);
        trace(accountNumberStr);

        var transactions = Pocketsmith.getTransactionsForTransactionAccount(apiKey, userId, accountNumberStr, null, null, sinceStr);

        trace("got transactions --- ");
        trace(transactions);

        var balance = 0.0;

        var convertedTransactions:Array<Transaction> = [];
        for (psTransaction in transactions) {
            if (balance == 0) {
                balance = psTransaction.transaction_account.current_balance;
            }

            var transaction:Transaction = {
                name: psTransaction.payee,
                accountNumber: Std.string(psTransaction.transaction_account.id),
                bankCode: "", // PocketSmith doesn't provide a direct equivalent
                amount: psTransaction.amount,
                currency: psTransaction.transaction_account.currency_code,
                bookingDate: Std.int(Date.fromString(psTransaction.date).getTime() / 1000),
                valueDate: Std.int(Date.fromString(psTransaction.date).getTime() / 1000),
                purpose: psTransaction.memo != null ? psTransaction.memo : "",
                transactionCode: 0, // PocketSmith doesn't provide a direct equivalent
                textKeyExtension: 0, // PocketSmith doesn't provide a direct equivalent
                purposeCode: "", // PocketSmith doesn't provide a direct equivalent
                bookingKey: "", // PocketSmith doesn't provide a direct equivalent
                bookingText: psTransaction.original_payee,
                primanotaNumber: "", // PocketSmith doesn't provide a direct equivalent
                batchReference: "", // PocketSmith doesn't provide a direct equivalent
                endToEndReference: "", // PocketSmith doesn't provide a direct equivalent
                mandateReference: "", // PocketSmith doesn't provide a direct equivalent
                creditorId: "", // PocketSmith doesn't provide a direct equivalent
                returnReason: "", // PocketSmith doesn't provide a direct equivalent
                booked: true // Assuming all transactions from PocketSmith are booked
            };
            convertedTransactions.push(transaction);
        }

        trace(convertedTransactions);

        return {
            balance: balance,
            transactions: Table.fromArray(convertedTransactions),
        }
    }

    @:luaDotMethod
    @:expose("EndSession")
    static function EndSession() {
        trace("EndSession got called");
    }

    static function main() {
        untyped __lua__("
        WebBanking {
            version = 1.0,
            url = 'https://www.pocketsmith.com',
            description = 'Pocketsmith',
            services = { 'Pocketsmith' },
        }
        ");

        untyped __lua__("
        function SupportsBank(protocol, bankCode)
            return _hx_exports.SupportsBank(protocol, bankCode)
        end
        ");

        untyped __lua__("
        function InitializeSession(protocol, bankCode, username, reserved, password)
            return _hx_exports.InitializeSession(protocol, bankCode, username, reserved, password)
        end
        ");

        untyped __lua__("
        function RefreshAccount(account, since)
            return _hx_exports.RefreshAccount(account, since)
        end
        ");

        untyped __lua__("
        function ListAccounts(knownAccounts)
            return _hx_exports.ListAccounts(knownAccounts)
        end
        ");

        untyped __lua__("
        function EndSession()
            return _hx_exports.EndSession()
        end
        ");
    }
}
