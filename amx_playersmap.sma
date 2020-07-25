/*
    PlayersMap v1.0
    https://www.github.com/PlayersMapAMXX/
*/

#include <amxmodx>
#include <geoip>
#include <sqlx>

#define VERSION "1.0"

#define SQL_HOST "-"
#define SQL_USERNAME "-"
#define SQL_PASSWORD "-"
#define SQL_DATABASE "-"

new Handle:g_MySQLConnection, Handle:g_MySQLTuple;
new Trie:g_PlayersCountry;
new g_szPlayerIPAddresses[MAX_PLAYERS][17];

public plugin_precache()
{
    register_plugin("PlayersMap", VERSION, "thEsp");

    new iError, szError[32];

    g_MySQLTuple = SQL_MakeDbTuple(SQL_HOST, SQL_USERNAME, SQL_PASSWORD, SQL_DATABASE);
    g_MySQLConnection = SQL_Connect(g_MySQLTuple, iError, szError, charsmax(szError));
    g_PlayersCountry = TrieCreate();

    if (g_MySQLConnection == Empty_Handle || g_MySQLTuple == Empty_Handle)
    {
        set_fail_state("Failed to create a MySQL connection. Error: %s", szError);
        return;
    }

    new szInitQuery[64];
    formatex(szInitQuery, charsmax(szInitQuery), "CREATE TABLE IF NOT EXISTS players (id varchar(3), value int);");
    SQL_ThreadQuery(g_MySQLTuple, "@SQL_Handler", szInitQuery);
}

public client_authorized(iPlayer)
{
    get_user_ip(iPlayer, g_szPlayerIPAddresses[iPlayer], charsmax(g_szPlayerIPAddresses[]));
    SaveStats(g_szPlayerIPAddresses[iPlayer], true);
}

public client_disconnected(iPlayer)
{
    SaveStats(g_szPlayerIPAddresses[iPlayer], false);
    g_szPlayerIPAddresses[iPlayer][0] = 0;
}

SaveStats(szIPAddress[], bool:bIn)
{
    new szCountryCode[3];
    geoip_code2_ex(szIPAddress, szCountryCode);
    
    new iPlayersPerCountry;
    TrieGetCell(g_PlayersCountry, szCountryCode, iPlayersPerCountry);
    TrieSetCell(g_PlayersCountry, szCountryCode, bIn ? ++iPlayersPerCountry : --iPlayersPerCountry);
    
    new szQuery[128];

    if (iPlayersPerCountry)
        formatex(szQuery, charsmax(szQuery), "DELETE FROM players WHERE id = '%s'; INSERT INTO players VALUES('%s', %i);", szCountryCode, szCountryCode, iPlayersPerCountry);
    else
        formatex(szQuery, charsmax(szQuery), "DELETE FROM players WHERE id = '%s';", szCountryCode);

    SQL_ThreadQuery(g_MySQLTuple, "@SQL_Handler", szQuery);
}

@SQL_Handler(iFailState, Handle:Query, szError[], iErrorCode, szData[], iDataSize)
{
    if (iFailState != TQUERY_SUCCESS)
    {
        log_amx("Failed to execute a SQL query. Error: %s", szError);
        return;
    }
}

public plugin_end()
{
    SQL_FreeHandle(g_MySQLConnection);
    SQL_FreeHandle(g_MySQLTuple);
    TrieDestroy(g_PlayersCountry);
}
