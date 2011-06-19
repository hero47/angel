package angel.common {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Defaults {
		
		public static const CHARACTER_HEALTH:int = 1;
		public static const MAIN_WEAPON_ID:String = "";
		public static const OFF_WEAPON_ID:String = "";
		public static const MOVE_POINTS:int = 10;
		public static const ACTIONS_PER_TURN:int = 2;
		public static const MOVE_SPEED:Number = 2; // speeds in adjacent-tiles-per-second
		public static const CHARACTER_DISPLAY_NAME:String = "Anonymous";
		public static const GUN_DISPLAY_NAME:String = "Gun";
		public static const GUN_DAMAGE:int = 10;
		public static const WEAPON_RANGE:int = 100;
		public static const WEAPON_COOLDOWN:int = 1;
		public static const TOP:int = 0;
		public static const MIN_FOR_OPPORTUNITY:int = 4;
		public static const PENALTY_WALK:int = 20;
		public static const PENALTY_RUN:int = 30;
		public static const PENALTY_SPRINT:int = 40;
		public static const DEFENSE_WALK:int = 20;
		public static const DEFENSE_RUN:int = 30;
		public static const DEFENSE_SPRINT:int = 40;
		public static const FIRE_FROM_COVER_DAMAGE_REDUCTION:int = 25;
		public static const MAX_GAIT:int = 3;
		public static const WEAPON_TYPE:String = "hand";
		
		public static const GAME_MENU_SPLASH_ID:String = "openmenu";
		
		public static const CONVERSATION:String = null;
			
		public function Defaults() {
		}
		
	}

}