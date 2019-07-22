use strict;
use WFAUtil;
use Getopt::Long;
use MIME::Base64;
use XML::Simple;
use REST::Client;
use JSON::PP;

my $JobId;
my $LL5Manager;
my $Template;
my $Customer;
my $NasPath;
my $vserverfqdn;
my $key;
my $value;
my $Sharename= "";
my $volname="";
my $qtreename="";
my $returnParamData;
my $estorageEmail = "estorage\@ford.com";
my $sizeingb;
GetOptions( "JobId=i" => \$JobId,"LL5Manager=s" => \$LL5Manager, "Template=s" => \$Template, "Customer=s" => \$Customer ) or die "Illegal Arguments \n" ;

my $wfa_util = WFAUtil->new();

$wfa_util->sendLog('INFO', "Job ID is $JobId");
my $server = "localhost";
my @Credentials = $wfa_util->getCredentials("$server");
my $username = $Credentials[0];
my $password = $Credentials[1];

#Preparing Headers and REST Client Object
my $encoded_auth = encode_base64("$username:$password", '');
my $headers = {
        'Authorization' => 'Basic ' . $encoded_auth,
        'Accept' => 'application/json',
    };
my $client = REST::Client->new(
        host => "http://$server");


my $json_data=$client->GET("/rest/workflows/jobs/$JobId",
              $headers)->responseContent();

$wfa_util->sendLog('INFO', $json_data);

my $decoded =decode_json($json_data);
my @res = @{$decoded->{'jobStatus'}{'returnParameters'}};
my $workflowname=$decoded->{'workflow'}{'name'};
my $jobStatus = $decoded->{'jobStatus'}{'jobStatus'};
$wfa_util->sendLog('INFO', $jobStatus);
$wfa_util->addWfaWorkflowParameter("jobStatus",$jobStatus);
if($jobStatus =~ /COMPLETED/ || $jobStatus =~ /EXECUTING/ || $jobStatus =~ /PARTIALLY SUCCESSFUL/ || $jobStatus =~ /SUCCESSFUL/)
{ 
$returnParamData = "<html><body style='background-color:powderblue;'><img src='https://media.github.ford.com/user/3261/files/8e81bd80-9761-11e9-92c6-2f503b96fad7' width=400 height=100'><br/><br/><p>Hello!<br/><br/>Thank you for provisioning the Storage through $Template!<br/><html><body><p><img src='https://media.github.ford.com/user/3261/files/86584e00-968d-11e9-8cff-bde16643c8b4' width=50 height=50'><br/><b><span style='background-color:green;'>Success Alert Message: Your storage provisioning request with JobID($JobId) was successful.</b></span><br/> 
                       </br><b><u>Below are the Mounting Path details of the NAS:</U></b><br/><br/></body></html>";

foreach my $r(@res)
{
$key=$r->{"key"};
$value=$r->{"value"};
$returnParamData="$returnParamData <b>$key:</b>$value<br/><br/>";
if(index($value,"/") != -1)
{
$NasPath = $value;
$wfa_util->sendLog('INFO', $NasPath);
}
if($key eq 'SMBShareName')
{
$Sharename=$value;
}
if($key eq 'StorageHostname')
{
$vserverfqdn = $value;                    
}
if($key eq 'RequestedSizeGB') {
$sizeingb = $value;
}
}
$returnParamData = "$returnParamData<br/>The LL5+ funding approver for this request ($LL5Manager) will receive an email with the cost details and next steps for approving the Budget. Funding must be approved within 30days or your storage will be decomissioned.<br/>If this is for PCF please click for next steps to attach <a href='https://github.ford.com/PCFDev-Reference/pcfdev-guides/tree/master/pcfdev-service-nfs-volume'>NFS storage</a> or <a href='https://github.ford.com/PCFDev-Reference/pcfdev-guides/tree/master/pcfdev-service-smb-volume'>SMB storage</a><br/><br/><b>Please ignore if this storage is not for the PCF.</b><br/><br/><b><u>Support:</u></b><br/><ul><li>If you have any questions or need further assistance regarding working with your new storage in your host environment, please contact the PCF host team.</li><li>If you need to make changes to your storage, please submit an Incident Ticket <a href='https://www.itconnect.ford.com/ux/rest/share/OJSXG33VOJRWKSLEHUYTCNBREZZGK43POVZGGZKUPFYGKPKTIJPVAUSPIZEUYRJGORSW4YLOOREWIPJQGAYDAMBQGAYDAMBQGAYDAMJGMNXW45DFPB2FI6LQMU6UGQKUIFGE6R27KNCUGVCJJ5HCMY3PNZ2GK6DUJFSD2NZXG4YGCNJZGAWTGMBVGQWTINRUMEWTQNBQHAWTKNJZMY3GEZJZMM4WEZA='>request</a></li><li>This email address is not monitored. Do not reply to this email.</li></ul><br/><b><u>Additional Resources:</u></b><br/><ul><li>To learn more about storage, including Unified Storage, File Services, Block Storage, storage billing and more, view these <a href='https://videosat.ford.com/#/media/search?q=staas'>storage videos</a></li></ul>.<br/><br/></br><b>Regards,</b><br/>Storage Engineering Team<br/>IT Business Innovation Center (ITBIC)<br/><img src='https://media.github.ford.com/user/3261/files/e4152f00-9349-11e9-95ae-5d66dc63d47b' width=300 height=150'></body></html>";
}
else{
$returnParamData = "<html><body style='background-color:powderblue;'><img src='https://media.github.ford.com/user/3261/files/8e81bd80-9761-11e9-92c6-2f503b96fad7' width=400 height=100'><br/><br/><p>Hello!<br/><br/><img src='http://www.pngall.com/wp-content/uploads/2016/04/Red-Cross-Mark-PNG-File.png' width=50 height=50'><b><span style='background-color:red;'>Failed Alert Message: Unfortunately, your storage provisioning request with jobId($JobId) has failed.</b></span><br/><br/> This can occur due to (network issues, etc.) so please try your provisioning request again.<br/>If you receive a second failure notice, please contact the Ford Cloud Portal team by clicking <a href='https://communities.spt.ford.com/sites/PCF/Lists/FordCloudPortalForum/AllItems.aspx'>here</a> or the Storage Engineering team at <a>$estorageEmail</a>.<br/> If any issues raising an Incident ticket please follow the documentation procedure by clicking <a href='https://github.ford.com/SDDC/storage-service/blob/master/StaaS_BMC_User_Ticket.md'>here</a>.<br/><br/></br><b>Regards,</b><br/>Storage Engineering Team<br/>IT Business Innovation Center (ITBIC)<br/><img src='https://media.github.ford.com/user/3261/files/e4152f00-9349-11e9-95ae-5d66dc63d47b' width=300 height=150'></body></html>";
}
my $jobfile="jobid_$JobId";
my $filename = "C:\\temp\\$jobfile.html";
$wfa_util->sendLog('INFO', $filename);
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh $returnParamData;
close $fh;

if(defined $LL5Manager && $jobStatus =~ /COMPLETED/)
{
my $db="cm_storage";
my $hostname=$server;
my $user="wfa";
my $password="Wfa123";
my @vserver = split(/\./,$vserverfqdn);
$wfa_util->sendLog('INFO',"vserver Name is $vserver[0]");
my $vservername=$vserver[0];

if($NasPath ne "")
{
my @naspath = split('/',$NasPath);
$wfa_util->sendLog('INFO', "Volume Name is $naspath[1]");
$volname=$naspath[1];
$wfa_util->sendLog('INFO', "Qtree Name is $naspath[2]");
$qtreename=$naspath[2];
}

if($Sharename ne "" && $NasPath eq "")
{
my $volquery = "SELECT volume.name from cm_storage.volume,cm_storage.qtree,cm_storage.vserver WHERE qtree.volume_id = volume.id AND volume.vserver_id = vserver.id AND qtree.name = '$Sharename' AND vserver.name = '$vservername' ";
my @vol_query_res=$wfa_util->invokeMySqlQuery($volquery,$db,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "volume is $vol_query_res[0]");
$volname=$vol_query_res[0];
}

my $clusterquery="SELECT cluster.primary_address FROM cm_storage.vserver,cm_storage.cluster WHERE vserver.cluster_id=cluster.id AND vserver.name='$vservername'";
my $servicelevelquery="SELECT cm_storage.qos_policy_group.name FROM cm_storage.qos_policy_group,cm_storage.volume,cm_storage.vserver WHERE volume.qos_policy_group_id = qos_policy_group.id AND volume.vserver_id = vserver.id AND volume.name='$volname' AND vserver.name='$vservername'";
my $qtreesizequery = "SELECT cm_storage.qtree.disk_limit_mb FROM cm_storage.qtree WHERE cm_storage.qtree.path = '\/$volname\/$Sharename'";

my @cluster_query_res=$wfa_util->invokeMySqlQuery($clusterquery,$db,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "Cluster is $cluster_query_res[0]");

my $sizequery="SELECT cm_storage.volume.size_mb,cm_storage.vserver.name FROM cm_storage.volume,cm_storage.vserver WHERE volume.vserver_id=vserver.id AND vserver.name='$vservername' AND volume.name='$volname'";
my @size_query_res=$wfa_util->invokeMySqlQuery($sizequery,$db,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "Size of Volume is $size_query_res[0]");
my @qtree_size_query_res=$wfa_util->invokeMySqlQuery($qtreesizequery,$db,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "Size of Qtree is $qtree_size_query_res[0]");
my $qtreesize = $qtree_size_query_res[0]/1024;
$wfa_util->sendLog('INFO', "Vserver is $size_query_res[1]");
$sizeingb = $size_query_res[0]/1000;
my $vsAbv = $size_query_res[1];


my @servicelevel_query_res=$wfa_util->invokeMySqlQuery($servicelevelquery,$db,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "ServiceLevel is $servicelevel_query_res[0]");
my $servicelevel = $servicelevel_query_res[0];
my @subsl = split('_',$servicelevel);
$wfa_util->sendLog('INFO', "Sub ServiceLevel is $subsl[0]");
my $customdb="custom_maps";
my $customquery="Select custom_maps.config.value FROM custom_maps.config WHERE custom_maps.config.type = '$subsl[0]' AND custom_maps.config.name = 'cost_per_gb' ";
my @custom_query_res=$wfa_util->invokeMySqlQuery($customquery,$customdb,$hostname,3306,$user,$password);
$wfa_util->sendLog('INFO', "cost per gb is $custom_query_res[0]");
my $cost;
if($vsAbv =~ /bu/ || $vsAbv =~ /bc/ || $vsAbv =~ /mc/) {
$cost=2*$qtreesize*$custom_query_res[0];
}
else {
$cost=$qtreesize*$custom_query_res[0];
}
$wfa_util->sendLog('INFO', "Total Cost is $cost");
my $ll5Data = "<html><body style='background-color:powderblue;'><img src='https://media.github.ford.com/user/3261/files/8e81bd80-9761-11e9-92c6-2f503b96fad7' width=400 height=100'><br/><br/><p>Hello!<br/><br/>Thank you for provisioning the Storage through $Template!<br/><html><body><p><img src='https://media.github.ford.com/user/3261/files/86584e00-968d-11e9-8cff-bde16643c8b4' width=50 height=50'><b><br/><span style='background-color:green;'>Success Alert Message: Your storage provisioning request with JobID($JobId) was successful.</b></span><br/><br/> Your storage provisioning request (JobID $JobId) was successful.
                       <br/> ($Customer) have self-Provisioned the storage and has indicated that you are the funding approver for this request.
                       <br/> Chargeback will begin for the storage effective from today.<br/>
                       <br/>To Prevent the Storage from being de-provisioned,Please provide the following information by within 30days.<br/></br>
                       <b><u>Below are the Budgetary details of the Storage:</u></b><br/>";
$ll5Data="$ll5Data<b>Storage Size:</b>$sizeingb<b>GB</b><br/><b>StorageServiceLevel:</b>$servicelevel_query_res[0]<br/><b>Storage Drive Cost Details:\$</b>$cost</span><br/><br/></br><b>Regards,</b><br/>Storage Engineering Team<br/>IT Business Innovation Center (ITBIC)<br/><img src='https://media.github.ford.com/user/3261/files/e4152f00-9349-11e9-95ae-5d66dc63d47b' width=300 height=150'>";
my $ll5file="ll5_$JobId";
my $filename1 = "C:\\temp\\$ll5file.html";
$wfa_util->sendLog('INFO', $filename1);
open(my $fh1, '>', $filename1) or die "Could not open file '$filename1' $!";
print $fh1 $ll5Data;
close $fh1;
}