package stage;

import java.util.Properties;
import fr.labri.harmony.core.analysis.AbstractAnalysis;
import fr.labri.harmony.core.config.model.AnalysisConfiguration;
import fr.labri.harmony.core.dao.Dao;
import fr.labri.harmony.core.model.Source;


public class Analysis extends AbstractAnalysis{

	public Analysis() {
		super();
	}

	public Analysis(AnalysisConfiguration config, Dao dao, Properties properties) {
		super(config, dao, properties);
	}

	@Override
	public void runOn(Source src) {
	// TODO Implement your analysis here
	}

}