module test;

import std.stdio;
import std.datetime;
import std.typecons;
import std.conv;
import vibe.utils.memory;
StopWatch total;

alias Report = Tuple!(string, "descr", StopWatch, "sw", long, "msecs");
Report[] linearAddDel(int[] dataSz, int times = 100_000){

	string[] gcMem;
	Report[] reports;
	foreach (del; [false, true]){
		foreach (i; 0..dataSz.length){
			Report report;
			report.descr = "[" ~ dataSz[i].to!string ~ "B; " ~ times.to!string ~ ";";
			total.start();
			report.sw.start();
			
			if (!del)
				foreach (j; 0..times)
					gcMem ~= new string(dataSz[i]);
			
			else
				foreach (j; 0..times)
					delete gcMem[i];
			
			report.sw.stop();
			total.stop();
			report.msecs = report.sw.peek().msecs;
			report.descr ~= report.msecs.to!string ~ "]";
			reports ~= report;
		}
		gcMem = null;
	}
	return reports;
}

Report[] manualAddDel(int[] dataSz, int times = 100_000){

	char[][] gcMem;
	Report[] reports;
	foreach (del; [false, true]){
		foreach (i; 0..dataSz.length){
			Report report;
			report.descr = "[" ~ dataSz[i].to!string ~ "B; " ~ times.to!string ~ ";";
			total.start();
			report.sw.start();
			
			if (!del)
				foreach (j; 0..times)
					gcMem ~= allocArray!(char, true)(defaultAllocator(), dataSz[i]);

			else
				foreach (j; 0..times)
					freeArray!(char, true)(defaultAllocator(), gcMem[i]);

			report.sw.stop();
			total.stop();
			report.msecs = report.sw.peek().msecs;
			report.descr ~= report.msecs.to!string ~ "]";
			reports ~= report;
		}
	}
	gcMem = null;
	return reports;
}

void main(){

	int[] dataSz = [10, 20, 40, 100];
	int times = 100_000;
	Report[][] reportCollections; // [ [ addReport, delReport ] , ... ]
	reportCollections ~= manualAddDel(dataSz, times);
	reportCollections ~= linearAddDel(dataSz, times);

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
}

import std.math;
float round(float x, uint places)
{
	float pwr = pow(10.0, places);
	return std.math.round(x * pwr) / pwr;
}