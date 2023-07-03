/**
 * Classe permettant de définir les Objets Apex correspondant aux objets Eligibilité utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet d'Eligibilité et chaque Propriété Apex correspond à un
 * champ dans l'Objet Eligibilité
 *
 * @author Yara Bourdoukan
 * @date 3 Decembre 2020
 */
public class EligibilityObjects {
    public static String post = 'POST';
    public static String get = 'GET';
    public static string EligibilityByBuildingIDAPIUrl = '/v3/check/building/,';
    public static string buildingsAPIUrl = '/v3/buildings/';    // takes Building ID and provides the details
    public static string rawFeasibilityAPIUrl = '/v3/feasibility';

    public class EligibilityByBuildingID {
        //stair name, not used yet
        public string stair;
        //floor number, number>0 by default it is 0
        public integer floor;
        //door name, not used yet
        public string door;
        //Unique Building ID
        public string building_id;
    }
    public class EligibilityByBuildingIDResponse {
        public ResponseResult result;
        public ResponsePop pop;
        public ResponseBuilding building;
        public string pto;
        public ResponseOtb otb;
        // handle error message when status != 200
        public string message;
        public string status;
    }
    public class ResponseResult {
        public boolean already_covered;
        public boolean feasible;
        public ResponseErrors errors;
        public integer code;
        public ResponseWarnings warnings;
        public boolean building_covered;
        public string msg;
    }
    public class ResponseErrors {
        public string propertyname;
    }
    public class ResponseWarnings {
        public string propertyname;
    }
    public class ResponsePop {
        public string name;
        public boolean has_backup_path;
    }
    public class ResponseBuilding {
        public string gref;
        public string geom; // GeoJSON <Point> variable type
    }
    public class ResponseOtb {
        public string gref;
        public string geom;
        public boolean is_otbb;
    }

    // Responses for Buildings API
    public class BuildingsAPIResponse {
        public Integer nb_ent_c;
        public String last_auditor;
        public Boolean is_under_construction;
        public String other_ops_drop;
        public Integer nb_flat_b;
        public Geometry geom;
        public String import_gref;
        public Boolean is_invalid;
        public String date_survey;
        public Boolean is_inaccessible;
        public Integer nb_flat_empty;
        public String neighborhood;
        public Integer nb_ent_d;
        public Integer nb_ent_b;
        public String region;
        public String date_audited;
        public List<Pictures> pictures;
        public String zone_osp;
        public String country;
        public String town;
        public String survey_status;
        public Boolean is_slum;
        public Boolean is_empty;
        public Integer nb_flat_d;
        public Integer nb_flat_a;
        public String electrical_access;
        public Integer nb_ent_a;
        public String comment;
        public Integer nb_flat_c;
        public Boolean has_clients;
        public Integer nb_floors;
        public String last_surveyor;
        public String date_creation;
        public String gref;
        public String date_inventory;
        public String residence;
    }
    public class Pictures {
        public String taken_at;
        public String url;
    }
    public class Geometry {
        public List<Double> coordinates;
        public String type;
    }

    public class BuildingsAPIError {
        public String message;
        public Integer code;
        public Errors errors;
        public String status;
    }

    // Classes for Raw Feasibility API
    public class FeasibilityAPIRequest {
        public string stair;
        public integer floor;
        public string door;
        public string building_id;
    }

    public class FeasibilityAPIResponse {
        public Boolean feasible;
        public string reason;
        public FeasibilityInfo info;
    }

    public class FeasibilityInfo {
        public integer code;
        public string message;
        public Integer status;
    }

    public class FeasiblityError {
        public string message;
        public integer code;
        public List<String> errors;
        public string status;
    }

    public class Errors {}
}