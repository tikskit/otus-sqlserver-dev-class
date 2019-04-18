using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction(Name = "GetLevDistance", IsDeterministic = true, IsPrecise = false)]
    public static SqlInt32 LevenshteinDistance(SqlString str1, SqlString str2)
    {
        String source = str1.Value;
        String target = str2.Value;
        if (string.IsNullOrEmpty(source))
        {
            if (string.IsNullOrEmpty(target)) return 0;
            return target.Length;
        }
        if (string.IsNullOrEmpty(target)) return source.Length;

        if (source.Length > target.Length)
        {
            var temp = target;
            target = source;
            source = temp;
        }

        var m = target.Length;
        var n = source.Length;
        var distance = new int[2, m + 1];
        // Initialize the distance matrix
        for (var j = 1; j <= m; j++) distance[0, j] = j;

        var currentRow = 0;
        for (var i = 1; i <= n; ++i)
        {
            currentRow = i & 1;
            distance[currentRow, 0] = i;
            var previousRow = currentRow ^ 1;
            for (var j = 1; j <= m; j++)
            {
                var cost = (target[j - 1] == source[i - 1] ? 0 : 1);
                distance[currentRow, j] = Math.Min(Math.Min(
                            distance[previousRow, j] + 1,
                            distance[currentRow, j - 1] + 1),
                            distance[previousRow, j - 1] + cost);
            }
        }
        return distance[currentRow, m];
    }
}
