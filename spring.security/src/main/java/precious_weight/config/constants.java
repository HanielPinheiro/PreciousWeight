package precious_weight.config;

public class constants {
    public static final String BabyTableName = "babies";
    public static final String BabyTableFieldName_Id = "baby_id";
    public static final String BabyTableFieldName_Hash = "baby_hash";
    public static final String BabyTableFieldName_Image = "baby_image";

    public static final String ScaleTableName = "scales";
    public static final String ScaleTableFieldName_Id = "scale_id";
    public static final String ScaleTableFieldName_Hash = "scale_hash";
    public static final String ScaleTableFieldName_State = "scale_state";
    public static final String ScaleTableFieldName_Image = "scale_image";

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

    public static final String LogsFieldName_Id = "log_id";
    public static final String LogsFieldName_Date = "log_date";

    public static final String BabyLogsTableName = "baby_logs";
    public static final String BabyLogsFieldName_NewId = "new_scale_id";

    public static final String ScaleLogsTableName = "scale_logs";
    public static final String ScaleFieldName_NewState = "new_scale_state";

    public static final String ControllerName_List = "/list";
    public static final String ControllerName_Save = "/save";
    public static final String ControllerName_Search = "/search/{id}";
    public static final String ControllerName_Delete = "/delete/{id}";
    public static final String ControllerName_Image = "/image/{id}";

    public static final String LoginControllerName = "/login";
    public static final String LoginController_BackEndName = "precious_weight_backend";
    public static final String LoginController_Scope = "scope";

    public static final String BabyControllerName = "/babies";
    public static final String BabyControllerName_Update = "/update/{id}";

    public static final String ScaleControllerName = "/scales";

    public static final String WeightControllerName = "/weight";

    public static final String UserControllerName = "/users";
    public static final String UserControllerName_New = "/new";

    public static final String ScaleLogsControllerName = "/logs/scales";
    public static final String BabyLogsControllerName = "/logs/babies";

}
