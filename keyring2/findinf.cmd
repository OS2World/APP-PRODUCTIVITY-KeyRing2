/* */
call rxfuncadd 'sysloadfuncs', 'rexxutil', 'sysloadfuncs'
call sysloadfuncs

call sysfiletree 'c:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'd:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'e:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'f:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'g:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'h:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'i:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

call sysfiletree 'j:\*.inf', 'file', 'FSO'
do i=1 to file.0
	say file.i
end

exit