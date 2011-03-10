package angel.game {
	import angel.common.Alert;

	
	public class Settings {
		
		public static const FRAMES_PER_SECOND:int = 30;
		public static const DEFAULT_MOVE_SPEED:Number = 2; // speeds in adjacent-tiles-per-second
		
		public static var testExploreScroll:int = 0;
		public static var combatMovePoints:int = 10;
		public static var walkPoints:int;
		public static var runPoints:int;
		public static var sprintPoints:int;
		
		public static var playerId:String = "Player";
		
		public function Settings() {
			
		}
		
		public static function initFromXml(xml:XMLList):void {
			var temp:String;
			Settings.testExploreScroll = (xml.@testExploreScroll);
			if (xml.@combatMovePoints.length() > 0) {
				combatMovePoints = xml.@combatMovePoints;
			}
			
			// XML should contain settings for two of the three percents.  We want to set movement points for those
			// two speeds based on percent of total points, then give the third one whatever's left (so rounding
			// errors fall into the unspecified one).
			// Then, once that's figured out, convert them to totals.
			walkPoints = combatMovePoints * int(xml.@walkPercent)/100;
			runPoints = combatMovePoints * int(xml.@runPercent)/100;
			sprintPoints = combatMovePoints * int(xml.@sprintPercent) / 100;
			if (walkPoints + runPoints + sprintPoints == 0) {
				walkPoints = runPoints = combatMovePoints / 3;
			}
			if (walkPoints == 0) {
				walkPoints = combatMovePoints - runPoints - sprintPoints;
			}
			if (runPoints == 0) {
				runPoints = combatMovePoints - walkPoints - sprintPoints;
			}
			if (sprintPoints == 0) {
				sprintPoints = combatMovePoints - walkPoints - runPoints;
			}
			if (walkPoints + runPoints + sprintPoints != combatMovePoints) {
				Alert.show("Bad walk/run/sprint values in init");
			}
			runPoints += walkPoints;
			sprintPoints += runPoints;
			
			if (xml.@player.length() > 0) {
				playerId = xml.@player;
			}
		}
		
	}

}