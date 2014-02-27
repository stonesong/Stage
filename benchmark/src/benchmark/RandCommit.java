package benchmark;

import javax.persistence.Access;
import javax.persistence.AccessType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
@Access(AccessType.PROPERTY)
public class RandCommit implements java.io.Serializable{

	/**
	 *
	 */
	private static final long serialVersionUID = -4882435137458918936L;

	private Integer randNum;
	private String nativeId;
	private int id;

	public RandCommit(){
		this.nativeId = null;
		this.randNum = null;

	}

	public RandCommit(Integer i, String s){
		this.nativeId = s;
		this.randNum = i;
	}


	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	@Column(name="NATIVE_ID")
	public String getNativeId(){
		return nativeId;
	}

	public void setNativeId(String s){
		this.nativeId = s;
	}


	@Column(name="RAND_NUM")
	public Integer getRandNum() {
		return randNum;
	}

	public void setRandNum(Integer i) {
		this.randNum = i;
	}

}