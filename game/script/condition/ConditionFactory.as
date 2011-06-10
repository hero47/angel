package angel.game.script.condition {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	public class ConditionFactory {
		
		private static const conditionNameToClass:Object = {
			"allOf":AndCondition,
			"anyOf":OrCondition,
			"alive":AliveCondition,
			"compare":CompareCondition,
			"empty":SpotEmptyCondition,
			"flag":FlagCondition,
			"inventoryHas":InventoryHasCondition,
			"pc":PcCondition
		}
		
		public function ConditionFactory() {
			Assert.fail("Should never be called");
		}
		
		public static function checkForShortcutVersion(actionXml:XML, rootScript:Script):ICondition {
			if (actionXml.attributes().length() == 1) {
				var attribute:XML = actionXml.attributes()[0];
				return createSimpleCondition(attribute.name(), String(attribute), rootScript);
			}
			return null;
		}
		
		public static function createFromXml(conditionXml:XML, rootScript:Script):ICondition {
			//Compiler bug: can't call createFromXml on a Class variable unless *this* class has one!!
			Assert.fail("Should never call this!");
			return null;
		}
	
		// If the xml contains just one condition element, create a condition from that.
		// If it contains more than one, create a condition and-ing them all together.
		// If ignoreScriptElement is true, ignore any element named "script" (for use directly inside an "if" action)
		public static function createFromEnclosingXml(actionXml:XML, rootScript:Script, ignoreScriptElement:Boolean = false):ICondition {
			var conditions:Vector.<ICondition> = new Vector.<ICondition>();
			for each (var checkXml:XML in actionXml.children()) {
				if (ignoreScriptElement && (checkXml.name() == "script")) {
					continue;
				}
				var classAndDesiredValue:ClassAndDesiredValue = convertNameToClassAndDesiredValue(checkXml.name(), rootScript);
				if (classAndDesiredValue != null) {
					var oneCondition:ICondition;
					if (isSimpleCondition(classAndDesiredValue.conditionClass)) {
						var param:String = checkXml.@param;
						if (param == "") {
							rootScript.addError(checkXml.name() + " condition requires param.");
							continue;
						}
						oneCondition = new classAndDesiredValue.conditionClass(checkXml.@param, classAndDesiredValue.desiredValue, rootScript);
					} else {
						oneCondition = classAndDesiredValue.conditionClass.createFromXml(checkXml, rootScript);
						if (!classAndDesiredValue.desiredValue) {
							oneCondition.reverseMeaning();
						}
					}
					if (oneCondition != null) {
						conditions.push(oneCondition);
					}
				}
			}
			
			if (conditions.length == 0) {
				return null;
			}
			return (conditions.length == 1) ? conditions[0] : new AndCondition(conditions, true);
		}
		
		static private function isSimpleCondition(conditionClass:Class):Boolean {
			var functionRef:Function = conditionClass["isSimpleCondition"] as Function;
			return functionRef();
		}
		
		static private function convertNameToClassAndDesiredValue(name:String, rootScript:Script):ClassAndDesiredValue {
			var desiredValue:Boolean = true;
			if (name.substr(0, 3) == "not") {
				name = name.substr(3, 1).toLowerCase() + name.substr(4);
				desiredValue = false;
			}
			
			var conditionClass:Class = conditionNameToClass[name];
			if (conditionClass == null) {
				rootScript.addError("Unknown condition " + name);
				return null;
			}
			return new ClassAndDesiredValue(conditionClass, desiredValue);
		}
		
		static private function createSimpleCondition(name:String, param:String, rootScript:Script):ICondition {
			var classAndDesiredValue:ClassAndDesiredValue = convertNameToClassAndDesiredValue(name, rootScript);
			if (classAndDesiredValue == null) {
				return null;
			}
			
			if (!isSimpleCondition(classAndDesiredValue.conditionClass)) {
				rootScript.addError(name + " cannot be used in 'if' shortcut version.");
				return null;
			}
			return new classAndDesiredValue.conditionClass(param, classAndDesiredValue.desiredValue, rootScript);
		}
		
	}

}

class ClassAndDesiredValue {
	public var conditionClass:Class;
	public var desiredValue:Boolean;
	public function ClassAndDesiredValue(conditionClass:Class, desiredValue:Boolean) {
		this.conditionClass = conditionClass;
		this.desiredValue = desiredValue;
	}
}