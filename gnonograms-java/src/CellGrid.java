import java.awt.Graphics;
import java.awt.Color;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseEvent;

import javax.swing.JPanel;
import javax.swing.BorderFactory;

import java.util.EnumMap;

import static java.lang.System.out;

public class CellGrid extends JPanel implements MouseListener, MouseMotionListener{

	private static final long serialVersionUID = 1;
  private int rows, cols, currentRow, currentCol;
  private double rowh, colw;
  private Cell currentCell, previousCell;
  private Color[] colors;

  public Controller control;

 public CellGrid(int rows, int cols, Controller control) {
	 			this.control=control;
        this.rows=rows;
        this.cols=cols;
        this.addMouseListener(this);
        this.addMouseMotionListener(this);
        this.setBorder(BorderFactory.createLineBorder(Color.black));

        currentCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
        previousCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
        colors=new Color[6];
        colors[Resource.CELLSTATE_FILLED]=Color.blue;
        colors[Resource.CELLSTATE_EMPTY]=Color.yellow;
        colors[Resource.CELLSTATE_UNKNOWN]=Color.gray;

        currentRow=-1;
        currentCol=-1;
    }

@Override
  public void paintComponent(Graphics g) {
    rowh=((double)this.getHeight())/((double)rows);
    colw=(double)(this.getWidth())/((double)cols);

     super.paintComponent(g);

     for (int r=0;r<rows;r++){
       for(int c=0;c<cols;c++){
         g.setColor(colors[control.getDataFromRC(r,c)]);
         g.fillRect((int)(c*colw)+1,(int)(r*rowh)+1,(int)(colw-2),(int)(rowh-2));
       }
     }
  }
    public void mousePressed(MouseEvent e) {
       int r= (int)((double)(e.getY())/rowh);
       int c= (int)((double)(e.getX())/colw);
       int x= (int)(c*colw)+1;
       int y= (int)(r*rowh)+1;
       int b= e.getButton();
       int cs=Resource.CELLSTATE_UNDEFINED;

       if (e.getClickCount()>1) b=2;

       switch (b){
				  case MouseEvent.BUTTON1:
				  cs=Resource.CELLSTATE_FILLED;
				 	break;
				 case MouseEvent.BUTTON2:
				 	cs=Resource.CELLSTATE_UNKNOWN;
				 	break;
				 case MouseEvent.BUTTON3:
				 	cs=Resource.CELLSTATE_EMPTY;
				 	break;
				 default :
				 	break;
			 }
				updateCell(r,c,cs);
    }

    private void updateCell(int r,int c,int cs){
			if (cs==Resource.CELLSTATE_UNDEFINED) return;
			currentCell.set(r,c,cs);
			control.setDataFromCell(currentCell);
			control.updateLabelsFromModel(r,c);
			repaint();
		}

    public void mouseExited(MouseEvent e) {
       currentCell.clear();
       previousCell.clear();
    }

    public void mouseDragged(MouseEvent e) {
			int r= (int)((double)(e.getY())/rowh);
      int c= (int)((double)(e.getX())/colw);
      if (r== currentRow && c== currentCol) return;
      currentRow= r;
      currentCol= c;
      updateCell(r,c,currentCell.getState());
    }

    public void mouseMoved(MouseEvent e) {}
    public void mouseClicked(MouseEvent e) {}
    public void mouseReleased(MouseEvent e) {}
    public void mouseEntered(MouseEvent e) {}
}
