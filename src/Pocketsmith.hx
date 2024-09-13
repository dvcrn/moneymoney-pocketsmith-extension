import JsonHelper;
import lua.Table;
import RequestHelper;

typedef PSCategory = {
    id:Int,
    title:String,
    colour:Null<String>,
    is_transfer:Bool,
    is_bill:Bool,
    refund_behaviour:Null<String>,
    children:Array<Dynamic>,
    parent_id:Null<Int>,
    roll_up:Bool,
    created_at:String,
    updated_at:String
}

typedef PSTransaction = {
    id:Int,
    payee:String,
    original_payee:String,
    date:String,
    upload_source:String,
    category:PSCategory,
    closing_balance:Float,
    cheque_number:Null<String>,
    memo:Null<String>,
    amount:Float,
    amount_in_base_currency:Float,
    type:String,
    is_transfer:Bool,
    needs_review:Bool,
    status:String,
    note:Null<String>,
    labels:Array<Dynamic>,
    transaction_account:TransactionAccount,
    created_at:String,
    updated_at:String
}

typedef Institution = {
    id:Int,
    title:String,
    currency_code:String,
    colour:String,
    logo_url:String,
    favicon_data_uri:String,
    created_at:String,
    updated_at:String
}

enum abstract TransactionAccountType(String) {
    var Bank = "bank" ;
    var Credits = "credits" ;
    var Cash = "cash" ;
    var Stocks = "stocks" ;
    var Mortgage = "mortgage" ;
    var Loans = "loans" ;
    var Vehicle = "vehicle" ;
    var Property = "property" ;
    var Insurance = "insurance" ;
    var OtherAsset = "other_asset" ;
    var OtherLiability = "other_liability" ;
}

typedef TransactionAccount = {
    id:Int,
    account_id:Int,
    name:String,
    latest_feed_name:String,
    number:Null<String>,
    type:TransactionAccountType,
    offline:Bool,
    is_net_worth:Bool,
    currency_code:String,
    current_balance:Float,
    current_balance_in_base_currency:Float,
    current_balance_exchange_rate:Null<Float>,
    current_balance_date:String,
    current_balance_source:String,
    data_feeds_balance_type:String,
    safe_balance:Null<Float>,
    safe_balance_in_base_currency:Null<Float>,
    has_safe_balance_adjustment:Bool,
    starting_balance:Float,
    starting_balance_date:String,
    institution:Institution,
    data_feeds_account_id:String,
    data_feeds_connection_id:String,
    created_at:String,
    updated_at:String
}

typedef Scenario = {
    id:Int,
    account_id:Int,
    title:String,
    description:Null<String>,
    interest_rate:Float,
    interest_rate_repeat_id:Int,
    type:String,
    is_net_worth:Bool,
    minimum_value:Null<Float>,
    maximum_value:Null<Float>,
    achieve_date:Null<String>,
    starting_balance:Float,
    starting_balance_date:String,
    closing_balance:Null<Float>,
    closing_balance_date:Null<String>,
    current_balance:Float,
    current_balance_in_base_currency:Float,
    current_balance_exchange_rate:Null<Float>,
    current_balance_date:String,
    safe_balance:Null<Float>,
    safe_balance_in_base_currency:Null<Float>,
    has_safe_balance_adjustment:Bool,
    created_at:String,
    updated_at:String
}

typedef PocketsmithAccount = {
    id:Int,
    title:String,
    currency_code:String,
    current_balance:Float,
    current_balance_in_base_currency:Float,
    current_balance_exchange_rate:Null<Float>,
    current_balance_date:String,
    safe_balance:Null<Float>,
    safe_balance_in_base_currency:Null<Float>,
    has_safe_balance_adjustment:Bool,
    type:String,
    is_net_worth:Bool,
    primary_transaction_account:TransactionAccount,
    primary_scenario:Scenario,
    transaction_accounts:Array<TransactionAccount>,
    scenarios:Array<Scenario>,
    created_at:String,
    updated_at:String
}

typedef User = {
    id:Int,
    login:String,
    name:String,
    email:String,
    avatar_url:String,
    beta_user:Bool,
    country_code:String,
    time_zone:String,
    week_start_day:Int,
    is_reviewing_transactions:Bool,
    base_currency_code:String,
    always_show_base_currency:Bool,
    using_multiple_currencies:Bool,
    using_feed_support_requests:Bool,
    using_new_transactions_search:Bool,
    available_accounts:Int,
    available_budgets:Int,
    at_dashboard_limit:Bool,
    allowed_data_feeds:Bool,
    tell_a_friend_access:Null<Dynamic>,
    tell_a_friend_code:Null<String>,
    forecast_last_updated_at:String,
    forecast_last_accessed_at:String,
    forecast_start_date:String,
    forecast_end_date:String,
    forecast_defer_recalculate:Bool,
    forecast_needs_recalculate:Bool,
    feed_history_starts_from:Null<String>,
    feed_history_touched:Bool,
    last_logged_in_at:String,
    last_activity_at:String,
    created_at:String,
    updated_at:String
}

class Pocketsmith {
    public static function getCurrentUser(apiKey:String):User {
        var url = "https://api.pocketsmith.com/v2/me";
        var headers = [
            "accept" => "application/json",
            "X-Developer-Key" => apiKey,
        ];
        var response = RequestHelper.makeRequest(url, "GET", headers);
        trace(response.content);

        var parsed = JsonHelper.parse(response.content);

        return parsed;
    }

    public static function getAccounts(apiKey:String, userId:Int):Array<PocketsmithAccount> {
        var url = 'https://api.pocketsmith.com/v2/users/${userId}/accounts';
        var headers = [
            "accept" => "application/json",
            "X-Developer-Key" => apiKey,
        ];
        var response = RequestHelper.makeRequest(url, "GET", headers);
        var parsed:Array<PocketsmithAccount> = Table.toArray(JsonHelper.parse(response.content));
        return parsed;
    }

    public static function getTransactionAccounts(apiKey:String, userId:Int):Array<TransactionAccount> {
        var url = 'https://api.pocketsmith.com/v2/users/${userId}/transaction_accounts';
        var headers = [
            "accept" => "application/json",
            "X-Developer-Key" =>apiKey
        ];
        var response = RequestHelper.makeRequest(url, "GET", headers);
        var parsed:Array<TransactionAccount> = Table.toArray(JsonHelper.parse(response.content));
        return parsed;
    }

    public static function getTransactionsForTransactionAccount(apiKey: String, userId:Int, transactionAccountId:Int, startDate:Null<String> = null,
                                                                endDate:Null<String> = null, updatedSince:Null<String> = null):Array<PSTransaction> {
        var url = 'https://api.pocketsmith.com/v2/transaction_accounts/${transactionAccountId}/transactions';
        trace(url);

        var queryParams = [];
        if (startDate != null)
            queryParams.push('start_date=${startDate}');
        if (endDate != null)
            queryParams.push('end_date=${endDate}');
        if (updatedSince != null)
            queryParams.push('updated_since=${StringTools.urlEncode(updatedSince)}');
        if (queryParams.length > 0) {
            url += '?' + queryParams.join('&');
        }
        trace(queryParams);
        var headers = [
            "accept" => "application/json",
            "X-Developer-Key" => apiKey
        ];
        var response = RequestHelper.makeRequest(url, "GET", headers);
        var parsed:Array<PSTransaction> = Table.toArray(JsonHelper.parse(response.content));
        return parsed;
    }
}
