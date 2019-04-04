package com.interactive;

import java.io.File;
import java.io.FilenameFilter;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.f2i.energisticsStandardsApi.StringVector;
import com.f2i.energisticsStandardsApi.common.EpcDocument;
import com.f2i.energisticsStandardsApi.resqml2_0_1.AbstractIjkGridRepresentation;

public class TestFesapi {
	static {
		System.loadLibrary("FesapiCpp");
	}

	final static Logger logger = Logger.getLogger(TestFesapi.class.getName());

	public static void main(String[] args) {
		for (String filePath : args) {
			if (filePath == null)
				System.exit(1);
			if (!filePath.toLowerCase().endsWith(".epc"))
				System.exit(2);
			if (!new File(filePath).exists())
				System.exit(3);
			buildRepresentationsList(filePath, true, false);
			buildRepresentationsList(filePath, false, true);
			buildRepresentationsList(filePath, false, false);
		}
	}

	/**
	 * This methods return an ordered list of ijkRepresentation. Partial grid will
	 * be place after non partial ones.
	 *
	 * @param filePath
	 * @param includeGeometry
	 * @param includePartials
	 * @return an ordered list of ijkRepresentation. Partial grid will be place
	 *         after non partial ones.
	 */
	public static List<AbstractIjkGridRepresentation> buildRepresentationsList(final String filePath,
			boolean includeGeometry, boolean includePartials) {
		final File selectedGrid = new File(filePath);
		final File parentDirFile = selectedGrid.getParentFile();
		final List<File> fileList;
		if (parentDirFile != null)
			fileList = Arrays.asList(parentDirFile.listFiles(new FilenameFilter() {
				@Override
				public boolean accept(File dir, String name) {
					return name.endsWith(".epc");
				}
			}));
		else
			fileList = Arrays.asList(selectedGrid);

		// Move original selected grid on top of the list to be checked first
		// as geometry
		final int indexOf = fileList.indexOf(selectedGrid);
		if (indexOf > 0 && fileList.size() > 1) {
			final File swap = fileList.get(0);
			fileList.set(0, selectedGrid);
			fileList.set(indexOf, swap);
		}

		final LinkedList<AbstractIjkGridRepresentation> reps = new LinkedList();

		boolean isGeometryFound = false;
		for (File propertyFile : fileList) {
			EpcDocument pck = new EpcDocument(propertyFile.getAbsolutePath(), EpcDocument.openingMode.READ_ONLY) {
				@Override
				protected void finalize() {
				}
			};
			final String errorLog = pck.deserialize();
			final Logger logger = Logger.getLogger(TestFesapi.class.getName());

			final StringVector warnings = pck.getWarnings();
			for (int i = 0; i < warnings.size(); i++) {
				logger.log(Level.WARNING, warnings.get(i));
			}

			if (!"".equals(errorLog)) {
				logger.log(Level.WARNING, "Something bad while deserializing {0}", filePath);
				logger.log(Level.WARNING, "More info : {0}", errorLog);
			}

			long ijkGridRepresentationCount = pck.getIjkGridRepresentationCount();
			if (ijkGridRepresentationCount < 1) {
				logger.warning("There is no IJK grid in this file");
				continue;
			}

			if (ijkGridRepresentationCount > 1) {
				logger.warning("There is more than one IJK grid in this file. Selecting first one.");
			}

			for (int iRepInEpc = 0; iRepInEpc < ijkGridRepresentationCount; iRepInEpc++) {
				final AbstractIjkGridRepresentation ijkGridRep = pck.getIjkGridRepresentation(iRepInEpc);

				final boolean isPartial = ijkGridRep.isPartial();

				if (!isGeometryFound && includeGeometry && !isPartial) {
					reps.addFirst(ijkGridRep);
					isGeometryFound = true;
				}
				if (includePartials && isPartial) {
					reps.addLast(ijkGridRep);
				}

				reps.add(ijkGridRep);
			}
		}

		return reps;
	}
}
