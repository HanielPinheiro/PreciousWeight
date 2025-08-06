package precious_weight.config.system;

public class GlobalConstants {
    public static final String BabyTableName = "babies";
    public static final String BabyTableFieldName_Id = "baby_id";
    public static final String BabyTableFieldName_HospitalId = "baby_hospital_id";
    public static final String BabyTableFieldName_Image = "baby_image";
    public static final String BabyTableFieldName_ImageText = "baby_image_text";
    public static final String BabyTableFieldName_Name = "baby_name";
    public static final String BabyTableFieldName_MotherName = "baby_mother_name";
    public static final String BabyTableFieldName_BirthDate = "baby_birthdate";
    public static final String BabyTableFieldName_State = "baby_state";
    public static final String BabyTableFieldName_WeightHour = "baby_weight_hour";

    public static final String ScaleTableName = "scales";
    public static final String ScaleTableFieldName_Id = "scale_id";
    public static final String ScaleTableFieldName_Hash = "scale_hash";
    public static final String ScaleTableFieldName_State = "scale_state";

    public static final String WeightTableName = "weights";
    public static final String WeightTableFieldName_Id = "weight_id";
    public static final String WeightTableFieldName_Date = "weight_date";
    public static final String WeightTableFieldName_Value = "weight_value";

    public static final String UserTableName = "users";
    public static final String UserTableFieldName_Id = "user_id";
    public static final String UserTableFieldName_Email = "user_email";
    public static final String UserTableFieldName_Password = "user_password";
    public static final String UserTableFieldName_Organization = "user_org";

    public static final String RoleTableName = "roles";
    public static final String RoleTableFieldName_Id = "role_id";
    public static final String RoleTableFieldName_Name = "role_name";

    public static final String UserRoleRelationshipTableName = "user_roles_rel";

    public static final String ControllerName_List = "/list";
    public static final String ControllerName_Save = "/save";
    public static final String ControllerName_Search = "/search/{id}";
    public static final String ControllerName_Image = "/image/{id}";
    public static final String ControllerName_Enable= "/enable/{id}";
    public static final String ControllerName_Disable = "/disable/{id}";
    public static final String ControllerName_Update = "/update/{id}";

    public static final String LoginController_BackEndName = "precious_weight_backend";
    public static final String LoginController_Scope = "scope";
    public static final String LoginControllerName = "/login";
    public static final String LoginControllerName_Reset = "/reset";

    public static final String BabyControllerName = "/babies";

    public static final String ScaleControllerName = "/scales";
    public static final String ScaleControllerName_Save = "/save/{scaleHash}";

    public static final String ScaleControllerName_SetBaby = "/baby/set";
    public static final String ScaleControllerName_UnsetBaby = "/baby/unset";

    public static final String WeightControllerName = "/weight";
    public static final String WeightControllerName_Babies = "/babies/{babyId}";
    public static final String WeightControllerName_Scales = "/scales/{scaleId}";

    public static final String UserControllerName = "/users";
    public static final String UserControllerName_New = "/new";

    public static final String AuditControllerName = "/audit";
    public static final String AuditControllerName_Weights = "/weights/{babyId}";
    public static final String AuditControllerName_Scales = "/scales/{scaleId}";
    public static final String AuditControllerName_Babies = "/babies/{babyId}";

}
