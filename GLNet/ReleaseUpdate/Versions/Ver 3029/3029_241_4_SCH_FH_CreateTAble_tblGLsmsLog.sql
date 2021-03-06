IF not EXISTS (select * from sys.tables where name='TblGLSmsLog')
BEGIN

CREATE TABLE [dbo].[TblGLSmsLog](
	[SMS_ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[SMS_number] [nvarchar](50) COLLATE Arabic_CI_AS NULL,
	[SMS_Text] [nvarchar](800) COLLATE Arabic_CI_AS NULL,
	[Send_Status] [bit] NULL,
 CONSTRAINT [PK_TblGLSmsLog] PRIMARY KEY CLUSTERED 
(
	[SMS_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]



End 
