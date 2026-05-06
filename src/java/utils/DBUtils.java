/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 *
 * @author letha
 */
public class DBUtils {

	private static final String DRIVER_CLASS = "com.microsoft.sqlserver.jdbc.SQLServerDriver";

	private static final String DB_URL = System.getProperty(
			"db.url",
			"jdbc:sqlserver://localhost:1433;databaseName=BookingSystem;encrypt=true;trustServerCertificate=true"
	);
	private static final String DB_USER = System.getProperty("db.user", "sa");
	private static final String DB_PASSWORD = System.getProperty("db.password", "123");

	private DBUtils() {
	}

	public static Connection getConnection() throws SQLException {
		try {
			Class.forName(DRIVER_CLASS);
		} catch (ClassNotFoundException ex) {
			throw new SQLException("SQL Server JDBC driver not found in classpath. Please add mssql-jdbc jar to WEB-INF/lib.", ex);
		}
		return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
	}
}
