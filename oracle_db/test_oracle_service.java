import java.sql.*;

public class TestOracle {

    public static void main(String[] args) {

        String url = "jdbc:oracle:thin:@//HOST:1521/SERVICE_NAME";
        String user = "UserName";
        String password = "Password";

        try {

            System.out.println("Loading Oracle Driver...");
            Class.forName("oracle.jdbc.OracleDriver");

            System.out.println("Connecting...");

            Connection conn =
                DriverManager.getConnection(url, user, password);

            System.out.println("Connection OK");

            DatabaseMetaData meta = conn.getMetaData();

            System.out.println("Database : " +
                meta.getDatabaseProductName());

            System.out.println("Version  : " +
                meta.getDatabaseProductVersion());

            Statement st = conn.createStatement();

            ResultSet rs =
                st.executeQuery(
                    "select sys_context('USERENV','DB_NAME') from dual");

            while (rs.next()) {
                System.out.println(
                        "DB_NAME=" + rs.getString(1));
            }

            rs.close();
            st.close();
            conn.close();

            System.out.println("Test SUCCESS");

        } catch(Exception e) {
            System.out.println("Test FAILED");
            e.printStackTrace();
            System.exit(1);
        }
    }
}