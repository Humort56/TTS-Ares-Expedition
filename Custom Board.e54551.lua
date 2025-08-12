BeginnerProjects = false
BeginnerCorporations = false
PromoProjects = true
PromoCorporations = true

function onLoad()
	createButtons()
end

function createButtons()
	local paramSet = {
		{ position={3.4,1,-0.2},width=1200,height=300,label='Beginner Projects', scale={1,1,1.25},font_size=120,tooltip="Start with 4 beginner projects?", function_owner=self,click_function='toggleBProj' },
		{ position={6.4,1,-0.2},width=1200,height=300,label='Promo Projects', scale={1,1,1.25},font_size=120,color="Orange",tooltip="Include promo projects?", function_owner=self,click_function='togglePProj' },
		{ position={3.4,1,7.3},width=1200,height=300,label='Beginner Corporations', scale={1,1,1.25},font_size=120,tooltip="Start with beginner corporations?", function_owner=self,click_function='toggleBCorp' },
		{ position={6.4,1,7.3},width=1200,height=300,label='Promo Corporations', scale={1,1,1.25},font_size=120,color="Orange",tooltip="Include promo corporations?", function_owner=self,click_function='togglePCorp' },
		{ position={-4.3,1,6},width=1600,height=800,font_size=150,color={0,0,0,0}, click_function='startGame',tooltip="Start Expedition"}
	}
	for _,params in ipairs(paramSet) do
		self.createButton(params)
	end
end

function toggleBProj()
	BeginnerProjects = not BeginnerProjects
	local color = BeginnerProjects and "Orange" or "White"
	self.editButton({index=0,color=color})
end
function togglePProj()
	PromoProjects = not PromoProjects
	local color = PromoProjects and "Orange" or "White"
	self.editButton({index=1,color=color})
end
function toggleBCorp()
	BeginnerCorporations = not BeginnerCorporations
	local color = BeginnerCorporations and "Orange" or "White"
	self.editButton({index=2,color=color})
end
function togglePCorp()
	PromoCorporations = not PromoCorporations
	local color = PromoCorporations and "Orange" or "White"
	self.editButton({index=3,color=color})
end

function dummy()
end