#region Using directives
using System;
using FTOptix.Core;
using FTOptix.CoreBase;
using FTOptix.HMIProject;
using FTOptix.NativeUI;
using FTOptix.NetLogic;
using FTOptix.ODBCStore;
using FTOptix.Retentivity;
using FTOptix.Store;
using FTOptix.UI;
using Microsoft.Data.SqlClient;
using UAManagedCore;
using FTOptix.RAEtherNetIP;
using FTOptix.CommunicationDriver;
using OpcUa = UAManagedCore.OpcUa;
#endregion

public class Call_ProdDataSP : BaseNetLogic
{
    public override void Start()
    {
        // Insert code to be executed when the user-defined logic is started
    }

    public override void Stop()
    {
        // Insert code to be executed when the user-defined logic is stopped
    }

    [ExportMethod]
    public void CallInsertSummary()
    {
        //SP_Config = Project.Current.Get<InsertHrSummary_Config>("Model/SP_Exec/InsertHrSummary_Line1");
        InsertProdData_Config SP_Config = (InsertProdData_Config)Owner;
        //DB_Config = Project.Current.Get<DB_Config>("Model/DBConfigs/AMXProdDB");
        DB_Config DB_Config = (DB_Config)Owner.GetAlias("DB_Config");

        try
        {
            string connectionString = GenerateConnectionString(DB_Config);
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(SP_Config.SP, connection))
                {
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                    //Add input parameters
                    cmd.Parameters.AddWithValue("@PLC_TS", SP_Config.PLC_TS);
                    cmd.Parameters.AddWithValue("@ProdLine", SP_Config.ProdLine);
                    cmd.Parameters.AddWithValue("@EquipID", SP_Config.EquipID);
                    cmd.Parameters.AddWithValue("@ProdCount", SP_Config.ProdCount);
                    cmd.Parameters.AddWithValue("@CycleAvg", SP_Config.CycleAvg);
                    cmd.Parameters.AddWithValue("@Trigger", SP_Config.Trigger);

                    // Output parameters
                    SqlParameter transactionCompleteParam = new SqlParameter("@TransactionComplete", System.Data.SqlDbType.Bit)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    cmd.Parameters.Add(transactionCompleteParam);

                    SqlParameter errorNumberParam = new SqlParameter("@SQLErrorNumber", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    cmd.Parameters.Add(errorNumberParam);

                    SqlParameter errorDescriptionParam = new SqlParameter("@SQLErrorDescription", System.Data.SqlDbType.NVarChar, 4000)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    cmd.Parameters.Add(errorDescriptionParam);

                    connection.Open();
                    cmd.ExecuteNonQuery();

                    SP_Config.TransComplete = (bool)transactionCompleteParam.Value;
                    SP_Config.SQLErrNum = (int)errorNumberParam.Value;
                    SP_Config.SQLErrDesc = errorDescriptionParam.Value as string;
                }



            }
            SP_Config.Result = "Stored procedure called successfully.";
        }
        catch (Exception ex)
        {
            SP_Config.Result = ex.Message;
        }
    }


    private string GenerateConnectionString(DB_Config DB_Config)
    {
        SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder
        {
            DataSource = $"{DB_Config.Hostname},{DB_Config.Port}",
            InitialCatalog = DB_Config.DatabaseName,
            UserID = DB_Config.Username,
            Password = DB_Config.Password,
            IntegratedSecurity = false,
            TrustServerCertificate = true
        };

        return builder.ConnectionString;
    }

}
