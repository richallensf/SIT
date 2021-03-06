###############################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
# Collection of General Utilities
# Copyright (C) 2011  Michael Kapler
#
# For more information please visit my blog at www.SystematicInvestor.wordpress.com
# or drop me a line at TheSystematicInvestor at gmail
###############################################################################


###############################################################################
# Convenience Utilities
###############################################################################
# Split string into tokens using delim
###############################################################################
spl <- function
(
	s,			# input string
	delim = ','	# delimiter
)
{ 
	return(unlist(strsplit(s,delim))); 
}

###############################################################################
# Join vector of strings into one string using delim
###############################################################################
join <- function
(
	v, 			# vector of strings
	delim = ''	# delimiter
)
{ 
	return(paste(v,collapse=delim)); 
}

###############################################################################
# Remnove any leading and trailing spaces
###############################################################################
trim <- function
(
	s	# string
)
{
  s = sub(pattern = '^ +', replacement = '', x = s)
  s = sub(pattern = ' +$', replacement = '', x = s)
  return(s)
}

###############################################################################
# Get the length of vectors
############################################################################### 
len <- function
(
	x	# vector
)
{
	return(length(x)) 
}

###############################################################################
# Fast version of ifelse
############################################################################### 
iif <- function
(
	cond,		# condition
	truepart,	# true part
	falsepart	# false part
)
{
	if(len(cond) == 1) { if(cond) truepart else falsepart }
	else {  
		if(length(falsepart) == 1) {
			temp = falsepart
			falsepart = cond
			falsepart[] = temp
		}
		
		if(length(truepart) == 1) 
			falsepart[cond] = truepart 
		else 
			falsepart[cond] = truepart[cond]
			
		return(falsepart);
	}
} 

###############################################################################
# Check for NA, NaN, Inf
############################################################################### 
ifna <- function
(
	x,	# check x for NA, NaN, Inf
	y	# if found replace with y
) { 	
	return(iif(is.na(x) | is.nan(x) | is.infinite(x), y, x))
}

###############################################################################
# Count number of non NA elements
############################################################################### 
count <- function(
	x,			# matrix with data
	side = 2	# margin along which to count
)
{
	if( is.null(dim(x)) ) { 
		sum( !is.na(x) ) 
	} else { 
		apply(!is.na(x), side, sum) 
	}
}  

###############################################################################
# Running over window Count of non NA elements
############################################################################### 
run.count <- function
(
	x, 			# vector with data
	window.len	# window length
)
{ 
	n    = length(x) 
	xcount = cumsum( !is.na(x) )
	ycount = xcount[-c(1 : (k-1))] - c(0, xcount[-c((n-k+1) : n)])
	return( c( xcount[1:(k-1)], ycount))
}

###############################################################################
# Day of Week
############################################################################### 
date.dayofweek <- function(dates) 
{	
	return(as.double(format(dates, '%w')))
}

date.day <- function(dates) 
{	
	return(as.double(format(dates, '%d')))
}

date.week <- function(dates) 
{	
	return(as.double(format(dates, '%U')))
}
 
date.month <- function(dates) 
{	
	return(as.double(format(dates, '%m')))
}

date.year <- function(dates) 
{	
	return(as.double(format(dates, '%Y')))
}


date.week.ends <- function(dates) 
{	
	return( unique(c(which(diff( 100*date.year(dates) + date.week(dates) ) != 0), len(dates))) )
}

date.month.ends <- function(dates) 
{	
	return( unique(c(which(diff( 100*date.year(dates) + date.month(dates) ) != 0), len(dates))) )
}

date.year.ends <- function(dates) 
{	
	return( unique(c(which(diff( date.year(dates) ) != 0), len(dates))) )
}

# map any time series to monthly
map2monthly <- function(equity) 
{
	#a = coredata(Cl(to.monthly(equal.weight$equity)))

	if(compute.annual.factor(equity) >= 12) return(equity)
	
	dates = index(equity)
	equity = coredata(equity)

	temp = as.Date(c('', 10000*date.year(dates) + 100*date.month(dates) + 1), '%Y%m%d')[-1]
	new.dates = seq(temp[1], last(temp), by = 'month')		
	
	map = match( 100*date.year(dates) + date.month(dates), 100*date.year(new.dates) + date.month(new.dates) ) 
	temp = rep(NA, len(new.dates))
	temp[map] = equity
	
	#range(a - temp)
	
	return( make.xts( ifna.prev(temp), new.dates) )
}


# create monthly table
create.monthly.table <- function(monthly.data) 
{
	nperiods = nrow(monthly.data)
	
	years = date.year(index(monthly.data[c(1,nperiods)]))
		years = years[1] : years[2]

	# create monthly matrix
	temp = matrix( double(), len(years), 12)
		rownames(temp) = years
		colnames(temp) = spl('Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec')
	
	# align months
	index = date.month(index(monthly.data[c(1,nperiods)]))
	temp[] = matrix( c( rep(NA, index[1]-1), monthly.data, rep(NA, 12-index[2]) ), ncol=12, byrow = T)
		
	return(temp)
}
		

# http://www.mysmp.com/options/options-expiration-week.html
# The week beginning on Monday prior to the Saturday of options expiration is referred to as options expiration week. 
# Since the markets are closed on Saturday, the third Friday of each month represents options expiration.
# If the third Friday of the month is a holiday, all trading dates are moved forward; meaning that Thursday will be the last trading day to exercise options.
# http://www.cboe.com/TradTool/ExpirationCalendar.aspx

# The expiration date of stock options (3rd Friday of the month)
# http://bytes.com/topic/python/answers/161147-find-day-week-month-year
third.friday.month <- function(year, month)
{
	day = date.dayofweek( as.Date(c('', 10000*year + 100*month + 1), '%Y%m%d')[-1] )
	day = c(20,19,18,17,16,15,21)[1 + day]
	return(as.Date(c('', 10000*year + 100*month + day), '%Y%m%d')[-1])
}



###############################################################################
# Load Packages that are available and install ones that are not available.
############################################################################### 
load.packages <- function
(
	packages, 							# names of the packages separated by comma
	repos = "http://cran.r-project.org",# default repository
	dependencies = "Depends",				# install dependencies
	...									# other parameters to install.packages
)
{
	packages = spl(packages)
	for( ipackage in packages ) {
		if(!require(ipackage, quietly=TRUE, character.only = TRUE)) {
			install.packages(ipackage, repos=repos, dependencies=dependencies, ...) 
			
			if(!require(ipackage, quietly=TRUE, character.only = TRUE)) {
				stop("package", sQuote(ipackage), 'is needed.  Stopping')
			}
		}
	}
}


###############################################################################
# Timing Utilities
###############################################################################
# Begin timing
###############################################################################
tic <- function
(
	identifier	# integer value
)
{
	assign(paste('saved.time', identifier, sep=''), proc.time()[3], envir = .GlobalEnv)
}

###############################################################################
# End timing
###############################################################################
toc <- function
(
	identifier	# integer value
)
{
	if( exists(paste('saved.time', identifier, sep=''), envir = .GlobalEnv) ) {
	    prevTime = get(paste('saved.time', identifier, sep=''), envir = .GlobalEnv)
    	diffTimeSecs = proc.time()[3] - prevTime
    	cat('Elapsed time is', round(diffTimeSecs, 2), 'seconds\n')
    } else {
    	cat('Toc error\n')
    }    
    return (paste('Elapsed time is', round(diffTimeSecs,2), 'seconds', sep=' '))
}

###############################################################################
# Test for timing functions
###############################################################################
test.tic.toc <- function()
{
	tic(10)
	for( i in 1 : 100 ) {
		temp = runif(100)
	}
	toc(10)
}


###############################################################################
# Matrix Utilities
###############################################################################
# Lag matrix or vector
#  mlag(x,1) - use yesterday's values
#  mlag(x,-1) - use tomorrow's values
###############################################################################
mlag <- function
(
	m,			# matrix or vector
	nlag = 1	# number of lags
)
{ 
	# vector
	if( is.null(dim(m)) ) { 
		n = len(m)
		if(nlag > 0) {
			m[(nlag+1):n] = m[1:(n-nlag)]
			m[1:nlag] = NA
		} else if(nlag < 0) {
			m[1:(n+nlag)] = m[(1-nlag):n]
			m[(n+nlag+1):n] = NA
		} 	
		
	# matrix	
	} else {
		n = nrow(m)
		if(nlag > 0) {
			m[(nlag+1):n,] = m[1:(n-nlag),]
			m[1:nlag,] = NA
		} else if(nlag < 0) {
			m[1:(n+nlag),] = m[(1-nlag):n,]
			m[(n+nlag+1):n,] = NA
		} 
	}
	return(m);
}

###############################################################################
# Replicate and tile an array
# http://www.mathworks.com/help/techdoc/ref/repmat.html
###############################################################################
repmat <- function
(
	a,	# array
	n,	# number of copies along rows
	m	# number of copies along columns
)
{
	kronecker( matrix(1, n, m), a )
}

###############################################################################
# Compute correlations
###############################################################################
compute.cor <- function
(
	data, 		# matrix with data
	method = c("pearson", "kendall", "spearman")
)
{
	nr = nrow(data) 
	nc = ncol(data) 
	
	corm = matrix(NA,nc,nc)
	colnames(corm) = rownames(corm) = colnames(data)
		
	for( i in 1:(nc-1) ) {
		temp = data[,i]
		for( j in (i+1):nc ) {
			corm[i,j] = cor(temp, data[,j], use='complete.obs', method[1])	
		}
	}
	return(corm)
}

###############################################################################
# XTS helper functions
###############################################################################
# Create XTS object
###############################################################################
make.xts <- function
(
	x,			# data
	order.by	# date
)
{
	Sys.setenv(TZ = 'GMT')
	tzone = Sys.getenv('TZ')
	
    orderBy = class(order.by)
    index = as.numeric(as.POSIXct(order.by, tz = tzone))
    if( is.null(dim(x)) ) dim(x) = c(len(x), 1)

    x = structure(.Data = x, 
    	index = structure(index, tzone = tzone, tclass = orderBy), 
    	class = c('xts', 'zoo'), .indexCLASS = orderBy, .indexTZ = tzone)
	return( x )
}

###############################################################################
# Write XTS object to file
###############################################################################
write.xts <- function
(
	x,			# XTS object
	filename	# file name
)
{
	write.csv(x, row.names = index(x), filename)	
}

###############################################################################
# Work with file names
###############################################################################
get.extension <- function(x) 
{ 
	trim( tail(spl(x,'\\.'),1) ) 
}	

get.full.filename <- function(x) 
{ 
	trim( tail(spl(gsub('\\\\','/',x),'/'),1) ) 
}

get.filename <- function(x) 
{ 
	temp = spl(get.full.filename(x),'\\.')
	join(temp[-len(temp)])
}
