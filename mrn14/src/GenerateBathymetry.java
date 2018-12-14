
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;

public class GenerateBathymetry {
	/**
	 * This class shows how to create a Bathymetry File in Java
	 * @author maddienelson
	 * @param args
	 * @throws IOException 
	 */
	static String FS = System.getProperty("file.separator");
	
	
	
	/**Variables to change:
	 * FILE_PATH: change this to the file path in your computer where you have a folder 
	 * in which you want the files to be created. Note: this program does not  create a folder for you.
	 * Additionally, if you try to run the program and create a file with the same name as a file that
	 * already exits in that folder, it will tell you so and not overwrite the original file.
	 * NUM_TEST_FILES: This is the number of test files you would like to produce.
	 * FILE_NAME: The name that you want each file to have. It will generate "FILE_NAME0", "FILE_NAME1" ...
	 * NUM_ROWS: The number of rows you would like your bathymetry data to have.
	 * NUM_COLS: The number of columns you would like your bathymetry data to have.
	 * MAX_DEPTH: The maximum depth you want your bathymetry file to have.
	 * MIN_DEPTH: The minimum depth you want your bathymetry file to have.
	 */
	

	public static final String FILE_PATH = FS+"Users"+FS+"maddienelson"+FS+"Documents"+FS+"Bathymetry";
	public static final int NUM_TEST_FILES = 6;	
	public static final String FILE_NAME = "FallsLake";
	public static int NUM_ROWS = 8;
	public static int NUM_COLS = 20;
	private static final double MAX_DEPTH = 13.0;
	private static final double MIN_DEPTH = 5.0;
	
	
	public static final String BTY = ".bty";
	public static final String NL = "\n";
	public static final String SPACE = "  ";
	public static final String BIG_SPACE = "                     ";
	static double[][] grid;
	


	public static void main(String[] args) throws IOException {
		for(int fileNum = 0; fileNum<NUM_TEST_FILES; fileNum++) {
			initMakeFiles(fileNum);
		}
	}
	
	private static void initMakeFiles(int fileNum) throws IOException {
		String btyFileName = FILE_PATH+FS+FILE_NAME+fileNum+BTY;
		File btyFile = new File(btyFileName);
		checkFile(btyFile, btyFileName);
		makeBTYFile(fileNum,btyFile);
	}

	/**
	 * This function checks that the class will not overwrite any preexisting files.
	 * @param file
	 * @param name
	 * @throws IOException
	 */
	private static void checkFile(File file, String name) throws IOException {
		if(file.createNewFile()){
			System.out.println(name+" File Created");
		}
		else {
			System.out.println("File "+name+" already exists");
		}		
	}


	private static void makeBTYFile(int fileNum, File btyFile) throws IOException {
		makeGrid(fileNum+1);
		String str = createBTYString(fileNum);
		writeToFile(btyFile, str);
	}
	
	private static void writeToFile(File file, String str) throws IOException {
		BufferedWriter writer = new BufferedWriter(new FileWriter(file));
		writer.write(str);
		writer.close();			
	}

	private static String createBTYString(int fileNum) {
		StringBuilder str = new StringBuilder();
		String xLabels = generateLabel(NUM_COLS);
		String yLabels = generateLabel(NUM_ROWS);
		str.append("'R'"+NL);
		str.append(NUM_COLS+NL);
		str.append(xLabels+NL);  
		str.append(NUM_ROWS+NL);
		str.append(yLabels+NL);
		str.append(gridAsString()+NL);
		return str.toString();
	}


	private static String gridAsString() {
		StringBuilder gridStr = new StringBuilder();
		for (int i = 0; i<NUM_ROWS; i++) {
			for (int j = 0; j<NUM_COLS; j++) {
				gridStr.append(grid[i][j]+SPACE);
			}
			gridStr.append(NL);
		}
		return gridStr.toString();
	}


	private static void makeGrid(int num) {
		grid = new double[NUM_ROWS][NUM_COLS];
		makeSlopeQuad(0, 0, NUM_ROWS, NUM_COLS, num);
	}
	
	private static void makeSlopeQuad(int iStart, int jStart, int rowMax, int colMax,int num) {
		int midR = (int)((rowMax-iStart)/2);
		int midC = (int)((colMax-iStart)/2);
		for(int i = iStart; i<rowMax; i++) {
			for(int j = jStart; j<colMax; j++) {

				if(i<midR && j<midC) {
					grid[i][j]=(Math.floor((Math.abs(rowMax+colMax - i - j))*1000)/1000);
				}//bottomright
				else if(i<midR && j>=midC) {
					grid[i][j]=(Math.floor((Math.abs(j+colMax - i))*1000)/1000);
				}
				else if(i>=midR && j<midC) {
					grid[i][j]=(Math.floor((Math.abs(rowMax+ i - j))*1000)/1000);
				}
				else if(i>=midR && j>=midC) {
					grid[i][j]=(Math.floor((Math.abs( i + j))*1000)/1000);
				}
				else {
					grid[i][j] = i+j;
				}
			}
		}		
	}

	private static String generateLabel(int numVals) {
		StringBuilder label = new StringBuilder();
		double val = 0.0;
		for(int i = 0; i<numVals; i++) {
			val = (getMaxLabel(Math.floor(val+i)*1000)/1000)+5;
			label.append(val+SPACE);
		}
		return label.toString();
	}
	
	private static double getMaxLabel(double d) {
		return d;
	}
}
