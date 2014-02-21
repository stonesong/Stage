package benchmark;

import java.util.HashMap;
import java.util.Properties;
import java.util.Random;

import fr.labri.harmony.core.analysis.AbstractAnalysis;
import fr.labri.harmony.core.config.model.AnalysisConfiguration;
import fr.labri.harmony.core.dao.Dao;
import fr.labri.harmony.core.model.Source;


public class BenchmarkCreation extends AbstractAnalysis{

	
	static int NUMBER_OF_RAND = 1000; 

	
	public BenchmarkCreation() {
		super();
	}

	public BenchmarkCreation(AnalysisConfiguration config, Dao dao, Properties properties) {
		super(config, dao, properties);
	}

	@Override
	public void runOn(Source src) {
		HashMap<Integer, String> randMap = new HashMap<>();
		Random random = new Random();
		int rand; 
		
		System.out.println("Debut Analyse :");
		int totalCommits = src.getEvents().size();
		System.out.println("le dépot contient " + totalCommits + " commits");
	
		while (randMap.size() < NUMBER_OF_RAND){
			rand = random.nextInt(totalCommits);
			if (!randMap.containsKey(rand)){
				String nativeId = src.getEvents().get(rand).getNativeId();
				RandCommit rc = new RandCommit(rand, nativeId);
				
				randMap.put(rand, nativeId);
				dao.saveData(getPersitenceUnitName(), rc, src);
				
			}
			
		}
	}

}