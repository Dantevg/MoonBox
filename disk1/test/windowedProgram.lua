local x = 0
for k, v in pairs(screen.colors) do
	for i = 1, #v do
		screen.setColor( colors.compose(k,i-4) )
		screen.rect( x*(screen.width/11), (i-1)*(screen.height/7), screen.width/11, screen.height/7 )
	end
	x = x+1
end