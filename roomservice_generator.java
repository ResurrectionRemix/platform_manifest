import java.io.*;
class roomservice_generator
{
static BufferedReader stdin=new BufferedReader(new InputStreamReader(System.in));
public static void main(String args[])
{
roomservice rs=new roomservice();
String s="<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n <manifest> \n ";
//StringBuffer s=new StringBuffer("<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n <manifest> \n ");
int ch=0;
while(true)
{
System.out.println("Enter 1 for device, 2 for kernel,3 for vendor, any other integer to quit");
try
{
ch=Integer.parseInt(stdin.readLine());
}
catch(Exception e)
{
System.out.println("Exception occurred.\nAborting");
System.exit(0);
}
switch(ch)
{
case 1:s=s.concat(rs.device()+"\n");break;
case 2:s=s.concat(rs.kernel()+"\n");break;
case 3:s=s.concat(rs.vendor()+"\n");break;
//case 4:s=s.concat(rs.other()+"\n");break;
default:
try
{
    String filename= "../.repo/local_manifests/roomservice.xml";
    FileWriter fw = new FileWriter(filename,true); //the true will append the new data
    fw.write(s+"\n </manifest>");//appends the string to the file
    fw.close();
}
catch(IOException ioe)
{
    System.err.println("IOException: " + ioe.getMessage());
}
System.exit(0);
}
}
}
public String device()
{
String r="",name="",Vendor="",vendor="",gituser="",branch="";
System.out.println("Enter device name, followed by vendor name." +
"\nIf Samsung, then enter samsung. If lg,then lge. Check on github.com/TheMuppets.\n"+
"Then enter the github account where the repository exists, for example cyanogenmod, or westcripp.\n"+
"Then enter the revision, for example cm-12.0, or lp");
try
{
name=stdin.readLine();
Vendor=stdin.readLine();
vendor="android_device_"+Vendor+"_"+name;
gituser=stdin.readLine();
branch=stdin.readLine();
}
catch(Exception e)
{
System.out.println("Exception occurred. \nAborting");
System.exit(0);
}
r="<project name=\""+gituser+"/"+vendor+" path=\"device/"+Vendor+"/"+name+"\" revision=\""+branch+"\" remote=\"github\"/> ";
return r;
}
public String kernel()
{
String r="",name="",Vendor="",vendor="",gituser="",branch="";
System.out.println("Enter device name, followed by vendor name.\n" +
"Sometimes for kernel repositories the device name may be the board name, so enter that instead.\n" +
"For example, vendor name of android one devices is google, but the kernel is android_kernel_mediatek_sprout .\n" +
"Please check all this and then enter the required information.\n" +
"Then enter the github account where the repository exists, for example cyanogenmod, or westcripp.\n" +
"Then enter the revision, for example cm-12.0, or lp");
try
{
name=stdin.readLine();
Vendor=stdin.readLine();
vendor="android_kernel_"+Vendor+"_"+name;
gituser=stdin.readLine();
branch=stdin.readLine();
}
catch(Exception e)
{
System.out.println("Exception occurred. \nAborting");
System.exit(0);
}
r="<project name=\""+gituser+"/"+vendor+" path=\"kernel/"+Vendor+"/"+name+"\" revision=\""+branch+"\" remote=\"github\"/> ";
return r;
}
public String vendor()
{
String r="",name="",Vendor="",vendor="",gituser="",branch="";int ch=0;
System.out.println("Enter 1 if your vendor files are on github.com/TheMuppets \n"+
"Else enter any other integer");
try
{
ch=Integer.parseInt(stdin.readLine());
}
catch(Exception e)
{
System.out.println("Exception occurred.\n"+e+"\nAborting Program");
System.exit(0);
}
if(ch==1)
{
System.out.println("Enter vendor name.\nRevision will be taken as cm-12.0.\n"+
"If you need another revision, then edit the resultant roomservice.xml manually");
try
{
Vendor=stdin.readLine();
vendor="proprietary_vendor_"+Vendor;
r="<project name=\"TheMuppets/"+vendor+" path=\"vendor/"+Vendor+"\" revision=\"cm-12.0\" remote=\"github\"/> ";
}
catch(Exception e)
{
System.out.println("Exception occurred. \nAborting");
System.exit(0);
}
}
else
{
System.out.println("Enter device name, followed by vendor name." +
"Then enter the github account where the repository exists, for example cyanogenmod, or westcripp.\n"+
"Then enter the revision, for example cm-12.0, or lp");
try
{
name=stdin.readLine();
Vendor=stdin.readLine();
vendor="android_vendor_"+Vendor+"_"+name;
gituser=stdin.readLine();
branch=stdin.readLine();
r="<project name=\""+gituser+"/"+vendor+" path=\"vendor/"+Vendor+"/"+name+"\" revision=\""+branch+"\" remote=\"github\"/> ";
}
catch(Exception e)
{
System.out.println("Exception occurred. \nAborting");
System.exit(0);
}
}
return r;
}
}
