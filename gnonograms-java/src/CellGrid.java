import java.awt.Graphics;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionAdapter;
import java.awt.event.KeyAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.KeyEvent;


import javax.swing.JPanel;
import javax.swing.BorderFactory;

import java.util.EnumMap;

import static java.lang.System.out;
import java.lang.Math;

public class CellGrid extends JPanel{

	private static final long serialVersionUID = 1;
	private int rows, cols, currentRow, currentCol;
	private double rowHeight, columnWidth;
	private Cell currentCell, previousCell;
	private Color[] solvingColors;
	private Color[] settingColors;
	private Color[] displayColors;

	public Controller control;

 public CellGrid(int rows, int cols, Controller control) {
	 			this.control=control;
				this.rows=rows;
				this.cols=cols;
				this.addMouseListener(new GridMouseAdapter());
				this.addMouseMotionListener(new GridMouseMotionAdapter());
				this.addKeyListener(new GridKeyAdapter());
				this.setBorder(BorderFactory.createLineBorder(Color.black));
				//this.setPreferredSize(new Dimension(Math.min(cols*20,600), Math.min(rows*20,400)));

				currentCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
				previousCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
				solvingColors=new Color[6];
				solvingColors[Resource.CELLSTATE_FILLED]=Color.blue;
				solvingColors[Resource.CELLSTATE_EMPTY]=Color.yellow;
				solvingColors[Resource.CELLSTATE_UNKNOWN]=(new Color(190,190,190,0));
				settingColors=new Color[6];
				settingColors[Resource.CELLSTATE_FILLED]=Color.black;
				settingColors[Resource.CELLSTATE_EMPTY]=Color.white;
				settingColors[Resource.CELLSTATE_UNKNOWN]=Color.red;

				currentRow=-1;
				currentCol=-1;

				displayColors=settingColors;
		}

@Override
	public void paintComponent(Graphics g) {
		int gridWidth=this.getWidth();
		int gridHeight=this.getHeight();
		rowHeight=((double)gridHeight)/((double)rows);
		columnWidth=(double)(gridWidth)/((double)cols);

		super.paintComponent(g);

		for (int r=0;r<rows;r++){
		 for(int c=0;c<cols;c++){
			 g.setColor(displayColors[control.getDataFromRC(r,c)]);
			 g.fillRect((int)(c*columnWidth)+1,(int)(r*rowHeight)+1,(int)(columnWidth),(int)(rowHeight));
		 }
		}
		g.setColor(Color.gray);
		for (int r=0;r<rows;r++){
			int h=(int)(r*rowHeight);
			g.drawLine(0,h,gridWidth,h);
		}
		for (int c=0;c<cols;c++){
			int w=(int)(c*columnWidth);
			g.drawLine(w, 0, w, gridHeight);
		}
		g.setColor(Color.black);
		for (int r=0;r<=rows;r+=5){
			int h=(int)(r*rowHeight);
      g.drawLine(0,h,gridWidth,h);
			g.drawLine(0,h+1,gridWidth,h+1);
		}
		for (int c=0;c<=cols;c+=5){
			int w=(int)(c*columnWidth);
      g.drawLine(w, 0, w, gridHeight);
			g.drawLine(w+1, 0, w+1, gridHeight);
		}
	}

	protected void updateCell(int r,int c,int cs){
		if (cs==Resource.CELLSTATE_UNDEFINED) return;
		currentCell.set(r,c,cs);
		control.setDataFromCell(currentCell);
		control.updateLabelsFromModel(r,c);
		repaint();
	}

	public void setSolving(boolean	isSolving){
		if(isSolving) displayColors=solvingColors;
		else displayColors=settingColors;
	}

	private class GridMouseAdapter extends MouseAdapter{

		public void mousePressed(MouseEvent e) {
		 int r= (int)((double)(e.getY())/rowHeight);
		 int c= (int)((double)(e.getX())/columnWidth);
		 int x= (int)(c*columnWidth)+1;
		 int y= (int)(r*rowHeight)+1;
		 int b= e.getButton();
		 int cs=Resource.CELLSTATE_UNDEFINED;

		 if (e.getClickCount()>1) b=MouseEvent.BUTTON2;

		 switch (b){
				case MouseEvent.BUTTON1:
				cs=Resource.CELLSTATE_FILLED;
				break;
			 case MouseEvent.BUTTON2:
				if(control.isSolving)	cs=Resource.CELLSTATE_UNKNOWN;
				break;
			 case MouseEvent.BUTTON3:
				cs=Resource.CELLSTATE_EMPTY;
				break;
			 default :
				break;
		 }
			updateCell(r,c,cs);
		}
    public void mouseExited(MouseEvent e) {
		 currentCell.clear();
		 previousCell.clear();
    }
		public void mouseEntered(MouseEvent e) {
      //out.println("Entered grid");
		 requestFocus();
    }
	}

	private class GridMouseMotionAdapter extends MouseMotionAdapter{
		public void mouseDragged(MouseEvent e) {
			int r= (int)((double)(e.getY())/rowHeight);
			int c= (int)((double)(e.getX())/columnWidth);
			if (r== currentRow && c== currentCol) return;
      if (r<0||r>rows||c<0||c>=cols) return;
			currentRow= r;
			currentCol= c;
			updateCell(r,c,currentCell.getState());
    }
	}

  private class GridKeyAdapter extends KeyAdapter{
    public void keyPressed(KeyEvent e){
      int keyCode =e.getKeyCode();
      //out.println("KeyCode is "+keyCode);
      //out.println("VK_MINUS is "+KeyEvent.VK_MINUS);
      switch (keyCode){
        case KeyEvent.VK_MINUS:
              control.zoomFont(-2);
              break;
        case KeyEvent.VK_PLUS:
        case KeyEvent.VK_EQUALS:
              control.zoomFont(2);
              break;
        default:
          break;
      }
    }
  }
}
