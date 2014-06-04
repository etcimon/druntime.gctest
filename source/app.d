module test;

import std.stdio;
import std.datetime;
import std.typecons;
import std.conv;
import core.memory;
StopWatch total;

alias Report = Tuple!(string, "descr", StopWatch, "sw", long, "msecs");

size_t totalSize;
Report[] linearAddDel(int[] dataSz, int times = 100_000){

	string[] gcMem;
	Report[] reports;
	foreach (del; [false, true]){
		foreach (i; 0..dataSz.length){
			Report report;
			report.descr = "[" ~ dataSz[i].to!string ~ "B; " ~ times.to!string ~ ";";
			total.start();
			report.sw.start();
			
			if (!del){
				foreach (j; 0..times){
					gcMem ~= new string(dataSz[i]);
					totalSize += dataSz[i];
					if (totalSize > 100_000_000)
					{
						GC.collect();
						totalSize = 0;
					}
				}
			}else{
				foreach (j; 0..times)
					gcMem[i] = null;
			}
			report.sw.stop();
			total.stop();
			report.msecs = report.sw.peek().msecs;
			report.descr ~= report.msecs.to!string ~ "]";
			if (del) reports[i].msecs += report.msecs;
			else 
				reports ~= report;
		}
	}
	return reports;
}


Report[] mixedLinearAddDel(int[] dataSz, int times = 100_000){
	
	string[] gcMem;
	Report[] reports;
	foreach (i; 0..dataSz.length){
		
		
		Report report;
		report.descr = "[" ~ dataSz[i].to!string ~ "B; " ~ times.to!string ~ ";";
		total.start();
		report.sw.start();
		foreach (j; 0..times){
			gcMem ~= new string(dataSz[i]);
			 gcMem[i] = null;
		}
		report.sw.stop();
		total.stop();
		report.msecs = report.sw.peek().msecs;
		report.descr ~= report.msecs.to!string ~ "]";
		reports ~= report;
		
		
	}
	
	gcMem = null;
	return reports;
}



void main(){
	GCStats* stats = new GCStats();
	//stats.samplingMaxDiscrepancy = 8;
	//stats.disableSampling = false; 
	GC.stats(stats);
	GC.stats(stats); 
	int[] dataSz = [20, 50, 100, 500, 1000, 5000]; 
	int times = 10_000; 
	Report[][] reportCollections; // [ [ addReport, delReport ] , ... ]
	version(ManualMemory){ 
		reportCollections ~= manualAddDel(dataSz, times); 
		reportCollections ~= manualAddDel(dataSz, times); 
		reportCollections ~= mixedManualArrays(dataSz, times);
		reportCollections ~= mixedManualArrays(dataSz, times); 
	}else { 
		reportCollections ~= linearAddDel(dataSz, times); 
		reportCollections ~= linearAddDel(dataSz, times);
		reportCollections ~= linearAddDel(dataSz, times);
		reportCollections ~= linearAddDel(dataSz, times); 
		reportCollections ~= linearAddDel(dataSz, times);
		reportCollections ~= linearAddDel(dataSz, times); 
		reportCollections ~= linearAddDel(dataSz, times);
		reportCollections ~= linearAddDel(dataSz, times); 
	} 
	string[] diffDescr; 
	int i; 
	foreach (bytes; dataSz){ 
		foreach (j; 0..reportCollections.length - 1){
			long diff = reportCollections[j + 1][i].msecs - reportCollections[j][i].msecs;
			float perc = ((reportCollections[j + 1][i].msecs.to!float - reportCollections[j][i].msecs.to!float)/reportCollections[j][i].msecs.to!float*100f).round(2);
			string descr = "[" ~ bytes.to!string ~ "B; ";
			if (diff > 0)
				descr ~= "+";
			descr ~= diff.to!string ~ "ms; ";
			if (diff > 0)
				descr ~= "+";
			descr ~= perc.to!string ~ "%]";
			diffDescr ~= descr;
		}

		i++;
	}
	writeln("Differences of time it took between first and second runs of allocations: ");
	foreach (descr; diffDescr)
		writeln(descr);
	writeln("Total test took: " ~ total.peek().msecs.to!string ~ " ms");

	GC.stats(stats);
	//writeln(stats.samplingSamples, " samples");
	//writeln(stats.samplingPopulation, " population");
	//writeln(stats.totalSamplingFailures, " total sampling failures");
	//writeln(stats.totalSamplings, " total samplings");
	//writeln(stats.elapsedInSampling.msecs, " ms in sampling");
	writeln(stats.bytesUsedCurrently, "B in use");
	writeln(stats.bytesFreeCurrently, "B immediately available");
	writeln(stats.totalCollections, " collections");
	writeln(stats.bytesFreedInCollections, " freed");
	writeln(stats.bytesUsedInCollections, " used"); 
	writeln(stats.elapsedInCollections.msecs, " ms in collections"); 
	writeln(stats.elapsedInBigAllocations.msecs, " ms in big allocations"); 
	writeln(stats.elapsedInSmallAllocations.msecs, " ms in small allocations");
	writeln(stats.elapsed.msecs, " ms elapsed since GC start");
	writeln(stats.bytesFreedToOS, "B Freed to OS");
	writeln(stats.totalFreeToOS, " total Freed to OS");  
	writeln(stats.maxBytesUsed, "B Used at Highest Point");
	writeln(stats.maxBytesFree, "B Free at Highest Point");
	writeln((stats.bytesFreedInCollections.to!float/stats.bytesUsedInCollections.to!float)*100f, " avg freed % per collection");
}

import std.math;
float round(float x, uint places)
{
	float pwr = pow(10.0, places);
	return std.math.round(x * pwr) / pwr;
}