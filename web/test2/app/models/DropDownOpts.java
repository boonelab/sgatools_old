package models;

import java.util.ArrayList;
import java.util.List;

public class DropDownOpts {
	
	public static List<String> borders(){
		List<String> tmp = new ArrayList();
		tmp.add("0");
		tmp.add("1");
		tmp.add("2");
		tmp.add("3");
		tmp.add("4");
		tmp.add("5");
		return tmp;
	}
	
	public static List<String> replicates(){
		List<String> tmp = new ArrayList();

		tmp.add("4");
		tmp.add("1");
		return tmp;
	}
}
