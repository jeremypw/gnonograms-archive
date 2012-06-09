import javax.swing.JLabel;

public class GnonogramLabel extends JLabel{
  private static final long serialVersionUID = 1;
  private boolean isColumn;
  private String text;

  public GnonogramLabel(String text, boolean isColumn){
    this.isColumn=isColumn;
    this.text=text;

    if (isColumn) {
      this.setHorizontalAlignment(CENTER);
      this.setVerticalAlignment(BOTTOM);
    }else{
      this.setHorizontalAlignment(RIGHT);
      this.setVerticalAlignment(CENTER);
    }
    setText(text);
  }

  public String getOriginalText(){ return text;}

  public void setText(String text){
    this.text=text;
    if (isColumn) super.setText(verticalString(text));
    else super.setText(horizontalString(text));
  }

	private String verticalString (String s){
    String[] sa=s.split(Resource.BLOCKSEPARATOR);;
    StringBuilder sb=new StringBuilder("<html><P align='right'><b>");
    for (String ss : sa){
      sb.append(ss); sb.append("<br>");
    }
    sb.append("</b></P></html>");
    return sb.toString();
  }
	private String horizontalString (String s){
    return "<html><b>"+s+"</b></html>";
  }

}
