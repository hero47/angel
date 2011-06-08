package angel.game {
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.CharacterStats;
	import angel.common.Defaults;
	import angel.common.IEntityAnimation;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import angel.game.brain.CombatBrainNone;
	import angel.game.brain.IBrain;
	import angel.game.brain.UtilBrain;
	import angel.game.combat.Grenade;
	import angel.game.combat.IWeapon;
	import angel.game.combat.RoomCombat;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.event.EntityQEvent;
	import angel.game.inventory.Inventory;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class ComplexEntity extends SimpleEntity {
		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		public static const FACE_CAMERA:int = 1;
		
		private static const TEXT_OVER_HEAD_HEIGHT:int = 20;
		
		//NOTE: faction values come from a dropdown in the Room Editor, and are initialized from room files.
		public static const FACTION_ENEMY:int = 0;
		public static const FACTION_FRIEND:int = 1;
		public static const FACTION_NONE:int = 2;
		
		// Entity stats!
		// CONSIDER: Initial values for some of these come from a CharacterStats. I could have a CharacterStats embedded
		// here rather than individual variables for the ones that overlap, but currently (5/15/11) that's only two.
		protected var myDisplayName:String;
		public var maxHealth:int = 1;
		public var currentHealth:int;
		public var actionsPerTurn:int;
		public var actionsRemaining:int;
		public var hasCoverFrom:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
		public var exploreBrainClass:Class;
		public var exploreBrainParam:String;
		public var combatBrainClass:Class;
		public var combatBrainParam:String;
		public var brain:IBrain;
		public var inventory:Inventory = new Inventory();
		
		private var playerControlled:Boolean;
		public var faction:int;
		
		public var footprint:DisplayObject; // if non-null, drawn on decorations layer centered directly under me
		private var textOverHead:TextField;
		protected var facing:int;
		private var solidnessWhenAlive:uint;
		
		public var movement:EntityMovement;
		private var animation:IEntityAnimation;
		
		public function ComplexEntity(resource:RoomContentResource, id:String = "") {
			super(new Bitmap(resource.standardImage()), resource.solidness, id);
			
			var characterStats:CharacterStats = resource.characterStats;
			maxHealth = currentHealth = characterStats.health;
			actionsPerTurn = characterStats.actionsPerTurn;
			myDisplayName = characterStats.displayName;
			initMovement(characterStats.movePoints, characterStats.maxGait);
			if (characterStats.mainGun != "") {
				inventory.equip(Inventory.makeOne(characterStats.mainGun), Inventory.MAIN_HAND, false);
			}
			if (characterStats.offGun != "") {
				inventory.equip(Inventory.makeOne(characterStats.offGun), Inventory.OFF_HAND, false);
			}
			if (characterStats.inventory != "") {
				inventory.addToPileFromText(characterStats.inventory);
			}
			//UNDONE: get rid of this once files are converted
			if (characterStats.grenades > 0) {
				inventory.addToPileOfStuff(Inventory.makeOne("grenade"), characterStats.grenades);
			}
			
			solidness = solidnessWhenAlive = resource.solidness;
			
			facing = FACE_CAMERA;
			animation = new resource.animationData.animationClass(resource.animationData, this.imageBitmap);
		}
		
		public static function createFromRoomContentsXml(charXml:XML, version:int, catalog:Catalog):ComplexEntity {
			var id:String;
			
			//Delete older version support eventually
			if (version < 1) {
				id = charXml;
			} else {
				id = charXml.@id
			}
			
			var resource:RoomContentResource = catalog.retrieveCharacterResource(id);
			if (resource == null) { // Catalog had something with this id that's not a character resource
				return null;
			}
			
			var entity:ComplexEntity = new ComplexEntity(resource, id);
			entity.setBrain(true, UtilBrain.exploreBrainClassFromString(charXml.@explore), charXml.@exploreParam);
			entity.setBrain(false, UtilBrain.combatBrainClassFromString(charXml.@combat), charXml.@combatParam);
			entity.faction = int(charXml.@faction);
			entity.setCommonPropertiesFromXml(charXml);
			return entity;
		}
		
		override public function cleanup():void {
			if (brain != null) {
				brain.cleanup();
			}
			if (movement != null) {
				movement.cleanup();
			}
			super.cleanup();
		}
		
		override public function set x(value:Number):void {
			super.x = value;
			if (footprint != null) {
				footprint.x = this.x + this.width / 2;
			}
		}
		
		override public function set y(value:Number):void {
			super.y = value;
			if (footprint != null) {
				footprint.y = this.y + Tileset.TILE_HEIGHT / 2;
			}
		}
		
		override public function get displayName():String {
			return myDisplayName;
		}
		
		public function canMove():Boolean {
			//UNDONE: movement can't be null yet, see note in initMovement
			return ((movement != null) && (movement.maxDistanceForGait() > 0));
			//return (movement != null);
		}
		
		public function moving():Boolean {
			return ((movement != null) && movement.moving());
		}
		
		// CONSIDER: maxGait is a hack, it will probably eventually be based on armor
		public function initMovement(points:int, maxGait:int):void {
			//UNDONE: Currently (5/20/11) we break horribly if movement is null.  Combat phase transition requires
			//getting a EntityEvent.MOVED, which is generated by the movement code.  I'm seriously considering
			//ripping out the current event-driven phase transitions and replacing with a state machine called
			//on enterFrame; if so, I should be able to get rid of that dependency.
			/*
			if (points == 0) {
				if (movement != null) {
					movement.cleanup();
					movement = null;
				}
			} else {
			*/
				if (movement == null) {
					movement = new EntityMovement(this, points, maxGait);
				} else {
					movement.setMovePoints(points);
				}
			/*
			}
			*/
		}
		
		public function attachFootprint(newFootprint:DisplayObject):void {
			if (footprint != null) {
				removeFootprint();
			}
			footprint = newFootprint;
			room.decorationsLayer.addChild(footprint);
			footprint.x = this.x + this.width / 2;
			footprint.y = this.y + Tileset.TILE_HEIGHT/2;
		}
		
		public function removeFootprint():void {
			if (footprint != null) {
				room.decorationsLayer.removeChild(footprint);
				footprint = null;
			}
		}
		
		public function changeFaction(newFaction:int):void {
			faction = newFaction;
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_FACTION));
		}
		
		//NOTE: set brain classes and anything they will need for instantiation before calling.
		public function changePlayerControl(willBePc:Boolean, newFaction:int):void {
			if (playerControlled == willBePc) {
				return;
			}
			playerControlled = willBePc;
			if (movement != null) {
				movement.setSpeeds(playerControlled);
			}
			adjustBrainForRoomMode(room.mode);
			if (room.mode != null) {
				room.mode.playerControlChanged(this, playerControlled);
			}
			changeFaction(newFaction);
		}
		
		public function get isPlayerControlled():Boolean {
			return (playerControlled || Settings.controlEnemies);
		}
		
		public function get isReallyPlayer():Boolean {
			return playerControlled;
		}
		
		public function isEnemyOf(entity:ComplexEntity):Boolean {
			if ((faction == FACTION_NONE) || (entity.faction == FACTION_NONE)) {
				return false;
			}
			return (faction != entity.faction);
		}
						
		public function isEnemy():Boolean {
			//CONSIDER: is this true, or will we want to have civilians with combat behavior that are untargetable?
			return (!playerControlled && (combatBrainClass != null) && (currentHealth > 0));
		}
		
		public function isAlive():Boolean {
			return (currentHealth > 0);
		}
		
		public function setBrain(forExplore:Boolean, newBrainClass:Class, newParam:String):void {
			if (forExplore) {
				exploreBrainClass = newBrainClass;
				exploreBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomExplore)) {
					adjustBrainForRoomMode(room.mode);
				}
			} else {
				combatBrainClass = (newBrainClass == null ? CombatBrainNone : newBrainClass);
				combatBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomCombat)) {
					adjustBrainForRoomMode(room.mode);
				}
			}
		}
		
		public function adjustBrainForRoomMode(mode:IRoomMode):void {
			if (brain != null) {
				brain.cleanup();
			}
			
			if (mode is RoomCombat) {
				brain = new combatBrainClass(this, mode, combatBrainParam);
			} else if ((mode is RoomExplore) && (exploreBrainClass != null)) {
				brain = new exploreBrainClass(this, mode, exploreBrainParam);
			} else {
				brain = null;
			}
		}
		
		public function damageDealtSpeedPercent():int {
			return 100 - (movement == null ? 0 : Settings.speedPenalties[movement.mostRecentGait]);
		}
		
		public function damageTakenSpeedPercent():int {
			return 100 - (movement == null ? 0 : Settings.speedDefenses[movement.mostRecentGait]);
		}
		
		public function takeDamage(baseDamage:int, speedReducesDamage:Boolean, coverDamageReductionPercent:int = 0):void {
			if (speedReducesDamage) {
				baseDamage = baseDamage * damageTakenSpeedPercent() / 100;
			}
			if (coverDamageReductionPercent > 0) {
				baseDamage = baseDamage * (100 - coverDamageReductionPercent) / 100;
			}
			currentHealth -= baseDamage;
			trace(aaId, "damaged for", baseDamage, ", health now", currentHealth);
			setTextOverHead(String(currentHealth));
			if (currentHealth > 0) {
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.HEALTH_CHANGE));
			} else {
				solidness ^= Prop.TALL; // Dead entities are short, by fiat.
				startDeathAnimation();
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.DEATH));
			}
		}
		
		// Reset health at start and end of combat.
		public function initHealth():void {
			currentHealth = maxHealth;
			animation.turnToFacing(facing); // stands back up if we were dead
			solidness = solidnessWhenAlive;
		}
		
		public function setTextOverHead(value:String):void {
			if ((value == null) && (textOverHead != null)) {
				textOverHead.visible = false;
			} else if (value != null) {
				if (textOverHead == null) {
					textOverHead = Util.textBox("", Prop.WIDTH, TEXT_OVER_HEAD_HEIGHT, TextFormatAlign.CENTER);
					textOverHead.background = true;
					textOverHead.autoSize = TextFieldAutoSize.CENTER;
					textOverHead.y = imageBitmap.y - TEXT_OVER_HEAD_HEIGHT - 2;
					addChild(textOverHead);
				}
				textOverHead.visible = true;
				textOverHead.text = value;
			}
		}
				
		public function startDeathAnimation():void {
			animation.startDeathAnimation();
		}
		
		public function adjustImageForMove(frameOfMove:int, totalFramesInMove:int):void {
			animation.adjustImageForMove(facing, frameOfMove, totalFramesInMove);
		}
		
		public function currentFacing():int {
			return facing;
		}
		
		public function turnToFacing(newFacing:int):void {
			facing = Util.negSafeMod(newFacing, 8);
			animation.turnToFacing(facing);
		}
		
		// Return the facing that closest approximates the tile's direction
		public function findFacingToTile(loc:Point):int {
			// The +360 ensures that angle / 45 will round the direction we want even if original angle was negative
			var angle:int = Util.findRotFacingVector(loc.subtract(myLocation)) + 360 + 22;
			return ((angle / 45) % 8);
		}
		
		// Turn to the facing that closest approximates the tile's direction
		public function turnToFaceTile(loc:Point):void {
			turnToFacing(findFacingToTile(loc));
		}
		
		public function centerRoomOnMe():void {
			room.x = (stage.stageWidth / 2) - this.x - this.width/2;
			room.y = (stage.stageHeight / 2) - this.y - this.height/2;
		}
		
		// If we're talking real world, this makes no sense -- cover would be directional, and we'd have to talk about
		// cover from a particular enemy.  Wm wants this move-to-shoot-from-cover thing to be available whenever you're
		// next to a "tall" blocker, regardless of whether there are even any enemies around at all, so...
		public function hasCover():Boolean {
			for each (var toNeighbor:Point in Pathfinder.neighborCheck) {
				var xNext:int = toNeighbor.x + myLocation.x;
				var yNext:int = toNeighbor.y + myLocation.y;
				var neighbor:Point = myLocation.add(toNeighbor);
				if ((xNext >= 0) && (xNext < room.size.x) && (yNext >= 0) && (yNext < room.size.y) && 
							room.blocksSight(xNext, yNext)) {
					return true;
				}
			}
			return false;
		}
		
		private function hasAUsableEquippedWeapon():Boolean {
			return ( ((inventory.mainWeapon() != null) && (inventory.mainWeapon().readyToFire())) ||
					 ((inventory.offWeapon() != null)  && (inventory.offWeapon().readyToFire())) );
		}
		
		public function hasAUsableWeapon():Boolean {
			return (hasAUsableEquippedWeapon() ||
					 (inventory.findFirstMatchingInPileOfStuff(Grenade) != null));
		}
		
		public function hasAUsableWeaponAndEnoughActions():Boolean {
			return ((hasAUsableEquippedWeapon() && (actionsRemaining > 0)) ||
					 ((inventory.findFirstMatchingInPileOfStuff(Grenade) != null) && (actionsRemaining > 1)));
		}
		
	} // end class ComplexEntity

}
