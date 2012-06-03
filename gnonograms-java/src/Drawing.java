import java.awt.Graphics;
import java.awt.Color;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import javax.swing.JPanel;
import javax.swing.BorderFactory;
import static java.lang.System.out;

public class CellGrid extends JPanel implements MouseListener
{
	public int rows, cols;

 public CellGrid(int rows, int cols) {
        this.setBorder(BorderFactory.createLineBorder(Color.black));
        this.rows=rows;
        this.cols=cols;
        this.addMouseListener(this);
    }

@Override
	public void paintComponent(Graphics g)
	{
		double w=(double) this.getWidth();
		double h=(double) this.getHeight();
		double rowh=h/((double)rows);
		double colw=w/((double)cols);

		 super.paintComponent(g);

		 g.setColor(Color.yellow);
		 for (int r=0;r<rows;r++)
		 {
			 for(int c=0;c<cols;c++)
			 {
				 //g.drawRect((int)(c*colw),(int)(r*rowh),(int)colw,(int)rowh);
				 g.fillRect((int)(c*colw)+1,(int)(r*rowh)+1,(int)colw-2,(int)rowh-2);
			 }
		 }
	}
    public void mousePressed(MouseEvent e) {
       saySomething("Mouse pressed; # of clicks: "
                    + e.getClickCount(), e);
    }

    public void mouseReleased(MouseEvent e) {
       saySomething("Mouse released; # of clicks: "
                    + e.getClickCount(), e);
    }

    public void mouseEntered(MouseEvent e) {
       saySomething("Mouse entered", e);
    }

    public void mouseExited(MouseEvent e) {
       saySomething("Mouse exited", e);
    }

    public void mouseClicked(MouseEvent e) {
       saySomething("Mouse clicked (# of clicks: "
                    + e.getClickCount() + ")", e);
    }

    void saySomething(String eventDescription, MouseEvent e) {
        out.println(eventDescription + " detected on "
                        + e.getComponent().getClass().getName()
                        + ".");
    }
}
