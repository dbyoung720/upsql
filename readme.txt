upsql �����ݿ� sql server ͨ����������

ԭ��˵����
1��ʹ�� bak ���ݿⱸ���ļ������û������Ͻ������ݿ⻹ԭ���ٺ�ԭ�е��û������ϵľ����ݿ����ȶԣ��������ݿ⡣
2���˳������� sql server ���ݿ���������֧���������ݿ⡣
3���˳���Ϊ�˱�֤��ȷ�ԺͿɹ۲��ԣ�û�����Ż�����Ҳû�����������ű���ֱ�����������ݿ⡣

ʹ��˵����
1�����뽫�˳��򣬷ŵ��û����ݿ���������������С�
2�����ݿ����ӣ���ȡ udl �ķ�ʽ�����û�� udl ���ݿ������ļ����ֶ����� udl �ļ����ŵ�����Ŀ¼�¡�������Զ���⵱ǰĿ¼�µ� udl �ļ���
3�����û����ݿ�����������ϣ����д˳���ѡ��Ҫ���������ݿ⣬��ѡ��Ҫ���������°汾���ݿⱸ���ļ�����������Ϳ����ˡ�
4�����ݿ�������������/��ͼ/�洢����/������/�Զ��庯�� �� ���/ɾ��/�޸ġ�




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

