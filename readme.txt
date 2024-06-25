upsql ：数据库 sql server 通用升级工具

原理说明：
1、使用 bak 数据库备份文件，在用户电脑上进行数据库还原，再和原有的用户电脑上的旧数据库作比对，升级数据库。
2、此程序仅针对 sql server 数据库升级，不支持其它数据库。
3、此程序为了保证正确性和可观测性，没有作优化处理。也没有生成升级脚本。直接升级旧数据库。

使用说明：
1、必须将此程序，放到用户数据库服务器电脑上运行。
2、数据库连接，采取 udl 的方式。如果没有 udl 数据库连接文件，手动创建 udl 文件，放到程序目录下。程序会自动检测当前目录下的 udl 文件。
3、在用户数据库服务器电脑上，运行此程序，选择要升级的数据库，再选择要升级到的新版本数据库备份文件，点击升级就可以了。
4、数据库升级包含：表/视图/存储过程/触发器/自定义函数 的 添加/删除/修改。




UpSQL: A Universal Upgrade Tool for Database SQL Server

Principle explanation:
1. Use bak database backup files, restore the database on the user's computer, compare it with the old database on the original user's computer, and upgrade the database.
2. This program is only for SQL Server database upgrades and does not support other databases.
3. This program was not optimized to ensure accuracy and observability. No upgrade script was generated either. Upgrade the old database directly.

instructions:
1. This program must be run on the user database server computer.
2. Database connection, using UDL method. If there is no UDL database connection file, manually create the UDL file and place it in the program directory. The program will automatically detect the UDL files in the current directory.
3. On the user database server computer, run this program, select the database to be upgraded, then select the backup file of the new version of the database to be upgraded to, and click Upgrade to complete it.
4. Database upgrade includes add/delete/modify tables/views/stored procedures/triggers/custom functions.

