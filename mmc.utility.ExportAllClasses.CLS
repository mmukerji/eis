<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25" zv="Cache for UNIX (Red Hat Enterprise Linux for x86-64) 2017.2.2 (Build 865_0_18507U)" ts="2020-05-21 11:59:29">
<Class name="mmc.utility.ExportAllClasses">
<Description><![CDATA[
This class is created to export all classes (excluding LUT, HL7, MAC, and SCH) for all namespaces
<!-- ;vc;
;vc;    Object: mmc.utility.ExportAllClasses.CLS/MMC.10
;vc; Component: CLS.mmc.utility.ExportAllClasses
;vc;  Location: MMC_Custom_LIVE
;vc; Date/Time: 30-Nov-17 14:22
;vc;      User: lfassman
;vc; --><p>Deltanji status:<table id='vcm' border='1' style='{font-size: 0.7em;}'><tr><td>Object</td><td>mmc.utility.ExportAllClasses.CLS/MMC.10</td></tr><tr><td>Component</td><td>CLS.mmc.utility.ExportAllClasses</td></tr><tr><td>Location</td><td>MMC_Custom_LIVE</td></tr><tr><td>Date/Time</td><td style='white-space: nowrap;'>30-Nov-17 14:22</td></tr><tr><td>User</td><td>lfassman</td></tr></table>
]]></Description>
<Super>Ens.Rule.FunctionSet</Super>
<TimeChanged>65517,49668.296114</TimeChanged>
<TimeCreated>63763,50779.735907</TimeCreated>

<UDLText name="T">
<Content><![CDATA[
// to run this do ##class(mmc.utility.ExportAllClasses).ZexportAll()

]]></Content>
</UDLText>

<Parameter name="ExcludedNamespace">
<Default>%SYS,DOCBOOK,ENSDEMO,ENSEMBLE,HSAALIB,HSLIB,HSSYS,SAMPLES,USER,VIEWERLIB</Default>
</Parameter>

<Method name="ZexportAll">
<ClassMethod>1</ClassMethod>
<FormalSpec>pFilePath:%String="/HSCodeExport/"</FormalSpec>
<Implementation><![CDATA[
	 
 	//JLI 07/31/2015 
 	// The following export excludes the custom SQL table globals
 	// 2/16/2016 exclude InterSystems-shipped namespaces
	// 05/21/2020 Monty Comment
	
 	set currentns=$NAMESPACE
 	set tSC = ##class(%SYS.Namespace).ListAll(.namespaces)
 	set tInstance=##class(%SYS.System).GetInstanceName()
 	quit:$$$ISERR(tSC) tSC
 	set ns = $order(namespaces(""))
 	
 	while (ns '= "") {	
	             
 		if (##class(%EnsembleMgr).IsEnsembleNamespace()) && '(..#ExcludedNamespace [ ns) && ($e(ns,1,2) '= "^^"){
	 		zn ns	
	  		
	  		set tFilePath=pFilePath_ns_"_"_tInstance_"/"		
	  		if ('##class(%File).DirectoryExists(tFilePath))
	   		{
 	     		do ##class(%File).CreateDirectoryChain(tFilePath)
 	   		}
	 		//exporting globals for schedules and credentials
	 	
	  		do $system.OBJ.Export("^Ens.Util.ScheduleD.gbl",tFilePath_"SchExport.gbl_"_$zd($h,3)_".gbl")
	  		do $system.OBJ.Export("^Ens.Conf.CredentialsD.gbl",tFilePath_"CredExport.gbl_"_$zd($h,3)_".gbl")
	 
	  		set rs=##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog") 
	 		//exporting the custom schema 
	 		do rs.Execute("*.HL7",,4,0,1)
	    	while rs.Next(){
		  		set tFileName=rs.GetData(1)
		  		// JLI 09-16-15 This is to exclude out of box schema for the export
		  		set exclusionList="ITK.HL7,2.1.HL7,2.2.HL7,2.3.1.HL7,2.3.HL7,2.4.HL7,2.5.1.HL7,2.5.HL7,2.6.HL7,2.7.1.HL7,2.7.HL7"
		  		if (..NotIn(tFileName,exclusionList)){
		  			do $system.OBJ.Export(tFileName,tFilePath_tFileName_"_"_$zd($h,3)_".xml")
		 		}
	   		} 
	 		//exporting lookup tables 
	  		do rs.Execute("*.LUT",,4,0,1)
	 	   	while rs.Next(){
		  		set tFileName=rs.GetData(1)
		 
		  		do $system.OBJ.Export(tFileName,tFilePath_tFileName_"_"_$zd($h,3)_".xml")
		  	} 
      		//exporting routines
     		if (ns="MMC_CUSTOM"){
     			do rs.Execute("*.MAC",,4,0,1)
	 	   		while rs.Next(){
		 	   		set tFileName=rs.GetData(1)
		 	   		if (($e(tFileName,1,2) '= "HS") && ($zconvert($e(tFileName,1,3),"U") '= "ENS")) {
		  				do $system.OBJ.Export(tFileName,tFilePath_tFileName_"_"_$zd($h,3)_".xml")
		 	   		}
		  		} 
     		}	   
	    
			//exporting all custom classes including production, routing rule, transformation, and custom functions
	  		do $system.OBJ.GetClassList(.list,)
	  		set tClassName = $order(list(""))
	  		while (tClassName '= ""){
		  		if ($e(tClassName,1,2) '= "HS") {
         			do $system.OBJ.Export(tClassName_".CLS",tFilePath_tClassName_"_"_$zd($h,3)_".xml")
		  		}
         		set tClassName=$order(list(tClassName))
      		}	
      		
			w !, ns
  		}
		set ns = $order(namespaces(ns))
	}
	zn currentns
   	// Export from Cache Audit Log, from %SYS namespace
		
	set tSC = ..ExportProductionChanges() 
	quit:$$$ISERR(tSC)	
    W !, "finished exporting"
    quit tSC
]]></Implementation>
</Method>

<Method name="ExportProductionChanges">
<ClassMethod>1</ClassMethod>
<FormalSpec>pFilePath:%String="/HSCodeExport/ProductionAudit/",pFileName:%String="ProductionChanges",pDaysBack:%Numeric=1</FormalSpec>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	//JGD 9/4/2015
	//
	set tSC = $$$OK
	Try {
	  	if ('##class(%File).DirectoryExists(pFilePath))
	   	{
 	     do ##class(%File).CreateDirectoryChain(pFilePath)
 	   	}

		set tCurrentNS=$ZNSPACE
		zn "%SYS"
		; Open file
		If $$$isUNIX {
			If "/" '= $Extract(pFilePath,*) { 
				set tFilePath = pFilePath_"/" 
				}
		}
		elseif "\" '= $Extract(pFilePath,*) { 
				set tFilePath = pFilePath_"\" 
		}
		
	 	Set tInstance=##class(%SYS.System).GetInstanceName()
		Set tFileName = pFilePath_pFileName_"_"_tInstance_"_"_$zd($h,3)_".txt"

		Set tFile = ##class(%File).%New(tFileName)
		Do tFile.Open("NWS")

		; Write header
		set tSC=tFile.WriteLine($C(10))
		set tSC=tFile.WriteLine("Production Changes "_$ZDATETIME($HOROLOG)_" for "_pDaysBack_" day(s) back:")
		set tSC=tFile.WriteLine($C(10))
		set tSC=tFile.WriteLine("ID"_$C(9)_"AuditIndex"_$C(9)_"CSPSessionID"_$C(9)_"ClientExecutableName"_$C(9)_"Description"_$C(9)_"Event"_$C(9)_"EventData"_$C(9)_"JobId"_$C(9)_"JobNumber"_$C(9)_"Namespace"_$C(9)_"OSUsername"_$C(9)_"Pid"_$C(9)_"SystemID"_$C(9)_"UTCTimeStamp"_$C(9)_"Username")
		set tSC=tFile.WriteLine($C(10))
		
		; Extract Production Changes from Cache Audit Log
		&sql(DECLARE C2 CURSOR FOR
			select ID, AuditIndex,CSPSessionID, ClientExecutableName, Description, Event, EventData, JobId, JobNumber, Namespace, OSUsername, Pid, SystemID, UTCTimeStamp, Username 
			into :tID, :tAuditIndex, :tCSPSessionID, :tClientExecutableName, :tDescription, :tEvent, :tEventData, :tJobId, :tJobNumber, :tNamespace, :tOSUsername, :tPid, :tSystemID, :tUTCTimeStamp, :tUsername 
			from %SYS.Audit
			where
			EventType = '%Production'
			and UTCTimeStamp > {fn TIMESTAMPADD(SQL_TSI_DAY,-:pDaysBack,GETUTCDATE())})
		&sql(OPEN C2)
		&sql(FETCH C2)	
			
		; Write each change to file
		set tCount=0
		While (SQLCODE = 0)
		{
    		set tCount=tCount + 1
    		; Convert UTC to Local date time 
    		set tID = ##class(%Library.UTC).ConvertUTCtoLocal($p(tID,"|",1))_"|"_$p(tID,"|",2,5)
    		set tSC=tFile.WriteLine(tID_$C(9)_tAuditIndex_$C(9)_tCSPSessionID_$C(9)_tClientExecutableName_$C(9)_tDescription_$C(9)_tEvent_$C(9)_tEventData_$C(9)_tJobId_$C(9)_tJobNumber_$C(9)_tNamespace_$C(9)_tOSUsername_$C(9)_tPid_$C(9)_tSystemID_$C(9)_tUTCTimeStamp_$C(9)_tUsername)
    		set tSC=tFile.WriteLine($C(10))
    		&sql(FETCH C2)
		}
		
		; Write footer and close
		&sql(CLOSE C2)
    	set tSC=tFile.WriteLine("Count: "_tCount)
    	set tSC=tFile.WriteLine($C(10))			
		do tFile.Close()
		zn tCurrentNS
	}
	Catch eException {
		set tSC=eException.AsStatus()
	}
	
	quit tSC
]]></Implementation>
</Method>
</Class>
</Export>
