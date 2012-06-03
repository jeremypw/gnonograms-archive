import static java.lang.System.out;
import javax.swing.ImageIcon;
import java.util.ArrayList;
import java.util.ListIterator;

public class Utils
{
	static public String clueFromintArray(int[] cs)
	{
		//out.println("block string from cell_state_array length %d\n", cs.length);
		StringBuilder sb= new StringBuilder("");
		int count=0, blocks=0;
		boolean counting=false;

		for (int i=0; i<cs.length; i++)
		{
			if (cs[i]==Resource.CELLSTATE_EMPTY)
			{
				if (counting)
				{
					sb.append(count);
					sb.append(Resource.BLOCKSEPARATOR);
					counting=false;
					count=0;
					blocks++;
				}
			}
			else if(cs[i]==Resource.CELLSTATE_FILLED)
			{
				counting=true;
				count++;
			}
			else
			{
				//out.println("Error in clue from cellstate array - Cellstate UNKNOWN OR IN ERROR\n");
				//break;
			}
		}
		if (counting)
		{
			sb.append(count);
			sb.append(Resource.BLOCKSEPARATOR);
			blocks++;
		}
		if (blocks==0) sb.append("0");
		else sb.setLength(sb.length() -1);

		return sb.toString();
	}

	public static String clue_from_block_array(int[] b)
	{
		StringBuilder sb=new StringBuilder("");
		for (int block : b)
		{
			sb.append(block);
			sb.append(Resource.BLOCKSEPARATOR);
		}
		sb.setLength(sb.length() -1);
		return sb.toString();
	}

  static public int[] cellStateArrayFromString(String s) throws NumberFormatException	{
		//out.println("int string: "+s);
		String[] data=removeBlankLines(s.split("[\\D\\n]",110));
		int[] csa=new int[data.length];
		for (int i=0; i<data.length; i++) {
			//out.println("Cell string"+data[i]+" as integer: "+csi);
			csa[i]=new Integer(data[i]);
		}
		return csa;
	}

	public static String[] removeBlankLines(String[] sa){
		//out.println("removeBlankLines - array length "+sa.length);
		ArrayList<String> al = new ArrayList<String>();
		int count=0;
		for (String s : sa) {
			//out.println("Length of "+s+" is "+s.length());
			if (s.length()>0) {al.add(s);count++;}
		}
    String[] result=new String[count];
    for(int i=0; i<count; i++){
			result[i]=al.get(i);
		}
		return result;
	}

	public static int[] blockArrayFromClue(String s)
	{
		//stdout.printf(@"Block array from clue $s \n");
		String[] clues=removeBlankLines(s.split("[\\D\\n]",50));

		if(clues.length==0) {
			clues=new String[1]; clues[0]="0";
		}
		int[] blocks=new int[clues.length];

		for (int i=0;i<clues.length;i++) {
			//out.println("Clue "+i+" is '"+clues[i]+"'");
			blocks[i]=Integer.parseInt(clues[i]);
			//out.println("Block "+i+" is "+blocks[i]);
		}

		return blocks;
	}

	public static boolean showConfirmDialog(String s){
		out.println("Confirm "+s);
		//TO BE COMPLETED
		return true;
	}
	public static boolean showWarningDialog(String s){
		out.println("Warning "+s);
		//TO BE COMPLETED
		return true;
	}
	public static boolean showInfoDialog(String s){
		out.println("Info "+s);
		//TO BE COMPLETED
		return true;
	}

}
