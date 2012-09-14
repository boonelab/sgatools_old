package models;

import java.util.ArrayList;
import java.util.List;

public class HelpMessages {
	
	public static String plateFiles(){
		return "One or more tab delimited plain text file containing a header and:<ul>" +
				"<li>Three required columns (<b>row</b>, <b>column</b>, <b>colonysize</b>)</li>" +
				"<li>Two additional, optional, columns (<b>query</b> and <b>array</b>) can be added which indicate the ORF names corresponding to the row/column respectively</li>" +
				"<li>An additional column (<b>platenum</b>) if one file contains more than one screen</li>"+
				"</ul>" +
				"<center>"+
				"<br>" +
				"<b>Sample file:</b>"+
				"<table> " +
				"<tr> <td><center><b>row</b></center></td><td><center><b>column</b></center></td>" +
					"<td><center><b>colonysize</b></center></td><td><center><b><i>query</center></i></b></td><td><center><b><i>array</i></b></center></td><td><center><b><i>platenum</i></b></center></td> </tr> " +
				"<tr> <td><center>1</center></td><td><center>2</center></td><td><center>528.28</center></td><td><center>YPL280W</center></td><td><center>YPL279C</center></td><td><center>1</center></td> </tr> " +
				"<tr> <td><center>1</center></td><td><center>3</center></td><td><center>324.05</center></td><td><center>YPL280W</center></td><td><center>YFL052W</center></td><td><center>1</center></td> </tr> " +
				"<tr> <td colspan=6><center>.</center></td></tr> " +
				"<tr> <td colspan=6><center>.</center></td></tr> " +
				"<tr> <td><center>4</center></td><td><center>9</center></td><td><center>225.32</center></td><td><center>YFL065C</center></td><td><center>YPL279C</center></td><td><center>2</center></td> </tr> " +
				"</table></center>";
		
		
	}
	
	public static String arrayIgnoreFile(){
		return "<center>A plain text file with ORF names, line seperated, to be excluded from the normalization procedure" +
				"<br><br>" +
				"<b>Sample file:</b>"+
				"<table style='width:90px'> " +
				"<tr> <td><center>YPL280W</center></td> </tr> " +
				"<tr> <td><center>YPL279C</center></td></tr> " +
				"<tr> <td><center>YFL052W</center></td></tr> " +
				"<tr> <td><center>.</center></td></tr> " +
				"<tr> <td><center>.</center></td></tr> " +
				"<tr> <td><center>YFL065C</center></td></tr> " +
				"</table></center>";
		
	}
	
	public static String controlBorders(){
		return "<center>Value indicating number of outermost rows/columns containing control strains (typically 2 for an SGA screen)</center>";
	}
	
	public static String replicates(){
		return "<center>Value indicating number of colony replicates neighbouring one-another in the screen (typically 4 for an SGA screen)</center>";
	}
	
	public static String chromPosFile(){
		return "<center>A plain text file ORF names and their positions on chromsomes. The file should have 4 columns, <b>tab</b> separated (ORF name, ORF's chromosome, start position, end position)" +
				"<br><br>" +
				"<b>Sample file:</b>"+
				"<table style='width:200px'> " +
				"<tr> <td><center>YAL001C</center></td><td><center>1</center></td><td><center>151168</center></td><td><center>147596</center></td> </tr> " +
				"<tr> <td><center>YAL002W</center></td><td><center>1</center></td><td><center>143709</center></td><td><center>147533</center></td> </tr> " +
				"<tr> <td><center>YAL003W</center></td><td><center>1</center></td><td><center>142176</center></td><td><center>143162</center></td> </tr> " +
				"<tr> <td colspan=4><center>.</center></td></tr> " +
				"<tr> <td colspan=4><center>.</center></td></tr> " +
				"<tr> <td><center>YHR217C</center></td><td><center>8</center></td><td><center>557042</center></td><td><center>556581</center></td> </tr> " +
				"</table></center>";
		
	}
	
	public static String linkageCutoff(){
		return "<center>This value compliments the chromosome position file. ORFs within a proximity of this value with one another are excluded from the normalization</center>";
	}
}
