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
    if (isColumn) super.setText(verticalizeString(text));
    else super.setText(text);
  }

	private String verticalizeString (String s)
  {
    String vs;
    String[] sa;
    StringBuilder sb;

    sa=s.split(Resource.BLOCKSEPARATOR);

    sb=new StringBuilder("<html><P align='right'>");
    for (String ss : sa)
    {
      sb.append(ss);
      sb.append("<br>");
    }
    sb.append("</P></html>");
    return sb.toString();
  }

}
