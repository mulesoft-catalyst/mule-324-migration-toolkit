package org.mule.migration;


import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.xssf.usermodel.XSSFFormulaEvaluator;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.json.JSONArray;
import org.json.JSONObject;


public class GenerateMigrationEstimationExcel {
		
	public static InputStream populateMigrationEstimationTemplate(Object[] payload, String fileName) {

		final String TEMPLATE_FILE = "./ui/Migration-Estimate-Template.xlsx";
		final String ESTIMATE_SHEET_NAME = "Estimate";
		final String GENERAL_SHEET_NAME = "General";
		
		final String APPLICATION_NAME_JSONFIELD = "applicationName";
		final String COMPLEXITY_JSONFIELD = "complexity";
		final String AUTOMATION_JSONFIELD = "automation";
		final String SCORE_JSONFIELD = "score";
		final String EFFORT_T_SHIRT_JSONFIELD = "effortTShirt";
		final String SUMMARY_JSONFIELD = "summary";

		final int APPLICATION_NAME_XLCOLUMN = 0;
		final int COMPLEXITY_XLCOLUMN = 1;
		final int AUTOMATION_XLCOLUMN = 2;
		final int SCORE_XLCOLUMN = 3;
		final int EFFORT_T_SHIRT_XLCOLUMN = 4;
		final int FORMULA_XLCOLUMN = 5;
		final int SUMMARY_XLCOLUMN = 6;
				
		InputStream xlsxStream = null;
        
		try  
		{

			// Load the Estimation template file
			ClassLoader classLoader = GenerateMigrationEstimationExcel.class.getClassLoader();
			File file = new File(classLoader.getResource(TEMPLATE_FILE).getFile());
			XSSFWorkbook workbook = new XSSFWorkbook(new FileInputStream(file));

			// Prepare to populate the Estimate sheet
			JSONArray appDataArray = new JSONArray(payload);
			XSSFSheet estimateSheet = workbook.getSheet(ESTIMATE_SHEET_NAME);
			
			// For each appData populate the Estimate sheet with the details
			for (int index = 0; index < appDataArray.length(); index++) {
	            JSONObject appData = appDataArray.getJSONObject(index);
	            XSSFRow estimateRow = estimateSheet.createRow(index+1);	            
	            
	            estimateRow.createCell(APPLICATION_NAME_XLCOLUMN).setCellValue((String) appData.get(APPLICATION_NAME_JSONFIELD));	            
	            estimateRow.createCell(COMPLEXITY_XLCOLUMN).setCellValue((String) appData.get(COMPLEXITY_JSONFIELD));
	            estimateRow.createCell(SCORE_XLCOLUMN).setCellValue((int) appData.get(SCORE_JSONFIELD));
	            if (!"N/A".equals(appData.get(AUTOMATION_JSONFIELD))) {
		            estimateRow.createCell(AUTOMATION_XLCOLUMN).setCellValue(Double.parseDouble((String) appData.get(AUTOMATION_JSONFIELD)));	
	            }
	            estimateRow.createCell(EFFORT_T_SHIRT_XLCOLUMN).setCellValue((String) appData.get(EFFORT_T_SHIRT_JSONFIELD));
	            estimateRow.createCell(FORMULA_XLCOLUMN).setCellFormula(workbook.getSheet(GENERAL_SHEET_NAME).getRow(0).getCell(0).getStringCellValue());
	            
	            Cell summaryCell = estimateRow.createCell(SUMMARY_XLCOLUMN);
	            summaryCell.setCellValue((String) appData.get(SUMMARY_JSONFIELD));
	            summaryCell.getCellStyle().setWrapText(true);
	        }			
			
			estimateSheet.autoSizeColumn(APPLICATION_NAME_XLCOLUMN);
			workbook.setForceFormulaRecalculation(true);
			
			file = new File(fileName);
			workbook.write(new FileOutputStream(file));
			XSSFFormulaEvaluator.evaluateAllFormulaCells(workbook);

			workbook.close();
			
			xlsxStream = new FileInputStream(file);
			file.delete();
			
		} 
		catch (FileNotFoundException fnfe) {
	        	System.out.println("FileNotFoundException - " + fnfe.getMessage());
	        } 
		catch (IOException ioe) {
	        	System.out.println("IOException - " + ioe.getMessage());
	        }
		return xlsxStream;
	}


}

