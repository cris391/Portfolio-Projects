DROP TABLE IF EXISTS posts cascade;
DROP TABLE IF EXISTS questions cascade;
DROP TABLE IF EXISTS answers cascade;
DROP TABLE IF EXISTS comments cascade;
DROP TABLE IF EXISTS stack_users cascade;
DROP TABLE IF EXISTS app_users cascade;
DROP TABLE IF EXISTS search_history cascade;
DROP TABLE IF EXISTS markings cascade;
DROP TABLE IF EXISTS annotations cascade;
DROP TABLE IF EXISTS tags cascade;

CREATE TABLE stack_users(
userid int,
usercreationdate timestamp, 
userdisplayname text, 
userlocation text, 
userage int,
PRIMARY KEY (userid));

CREATE TABLE posts(
postid int, 
creationdate timestamp, 
score int, 
body text,
ownerid INTEGER REFERENCES stack_users(userid),
PRIMARY KEY (postid));

CREATE TABLE questions(
questionid int, 
closeddate timestamp, 
title text, 
acceptedanswerid int, 
postid int4,
PRIMARY KEY (questionid));

CREATE TABLE answers(
answerid int4, 
postid int4,
PRIMARY KEY (answerid));

CREATE TABLE comments(
commentid int, userid int, postid int, commentscore int, commenttext text, commentcreatedate timestamp);

CREATE TABLE app_users(
userid SERIAL NOT NULL, 
username text UNIQUE NOT NULL ,
password text NOT NULL,
salt text NOT NULL,
PRIMARY KEY (userid)
);

CREATE TABLE markings(
	markingid SERIAL NOT NULL,   
  userid INTEGER REFERENCES app_users(userid),
	postid INTEGER REFERENCES questions(questionid),
  PRIMARY KEY (markingid)
 );
 
 ALTER TABLE markings
 ADD CONSTRAINT userid_postid UNIQUE (userid,postid);
 
 CREATE TABLE annotations (
  annotationid SERIAL NOT NULL,
	markingid INTEGER REFERENCES markings(markingid) ON DELETE CASCADE,
  body TEXT,
  PRIMARY KEY (annotationid)
);

CREATE TABLE tags(
 questionid INTEGER REFERENCES questions(questionid),   
 value text
);

CREATE TABLE search_history(
searchdate timestamp, 
userid INTEGER REFERENCES app_users(userid), 
queryText text);


insert into comments(commentid, userid, postid, commentscore, commenttext, commentcreatedate) 
select distinct commentid, authorid, postid, commentscore, commenttext, commentcreatedate from comments_universal;

insert into app_users(username, password, salt) values 
	('user1', 'pass', 'dasadsdsa'),
	('user2', 'pass', 'dasadsdsa'),
	('user3', 'pass', 'dasadsdsa'),
	('user4', 'pass2', 'haha'),
	('cris32', 'N4tZNcDfzFPlGeCjW7ogVndAlTMuuGRCTvVEQ7tcLcH66l8cfSxN0M6vngtuyjRvH3uFfGyL7GoRFpw3QGj+zKByM+td6v04s5IVVuEhwC0hmdoTK9KZUOIByu46xuLCwFifUcz3YiFesD/u6ylKX7/GjvRf4fk5vfB1HYxbB6wctK/XbNrL6DHbWeVD1ci6YJztdEirykllCmyWYgdFKEzzk1Sp01kx7tTwlh04GCKE2xIF0ceqtenw0vNksmHWic83k/vz9r+d8leikBC37bRSJyosLYNepyXQ7bd5bfGkX9Ne/g4t0puvLragFtGt9d6Om/FirJwk7akls2z/kA==', 'ZFR5BJ6kSbSoVO+lMMjOEdorRL3vIYGS9kos769cDI/HL8xka+pig2iwwK6NCUlNY71J/z+LwT4XDJtEQ60N5tEAy9K4OAAqhvyHVJvT00WX1LbFtEfWN1PH67lOxDLV+UpYtuEEugwwWj1aU/gJDz57fCfJhp2Oof9DbCCjWEyMXcYR+RONResvGV1O+YmA47qi+bG6zCdgh5dVVxLE5brxgolqUJLQQTsvT87X5Vd8UObGu1g8UbwC97DT8C9OaoozcsbPjkn4ZRC1+OO3998SWFEhqOD0e2xMjBf5xJfFisjaQFHpUYdUieOiSuCc4OPlEs/gtGFxTxfiflADVg==');

insert into stack_users(userid, usercreationdate, userdisplayname, userlocation, userage) 
select distinct ownerid, ownercreationdate, ownerdisplayname, ownerlocation, ownerage from posts_universal;

insert into posts(
postid, creationdate, score, body, ownerid)
select distinct id, creationdate, score, body, ownerid from posts_universal;

insert into questions(
questionid, closeddate, title, acceptedanswerid, postid)
select distinct id, closeddate, title, acceptedanswerid, id from posts_universal where posttypeid = 1;

insert into answers(answerid, postid)
select distinct id answerid, parentid from posts_universal where posttypeid = 2;

 insert into markings(userid, postid) values
    (1, 16637748),
		(2, 16637748),
    (3, 16637748);
		
insert into tags(questionid, value) 
select id, tags from posts_universal where posttypeid = 1;

drop view if exists q_view;
create materialized view q_view as select q.questionid, p.creationdate, p.score, p.body, q.title, q.closeddate, q.acceptedanswerid 
from posts p
join questions q on q.questionid = p.postid;

drop view if exists a_view;
create materialized view a_view as select a.answerid, p.creationdate, p.score, p.body, a.postid
from posts p
join answers a on a.postid = p.postid;

-- functions
drop function if exists storeSearch(userid int, querytext text);
create or replace function storeSearch(userid int, querytext text)
	returns text as $$ 
	declare storedsearch text; 
	begin
		INSERT INTO search_history (searchdate, userid, querytext)
		VALUES (NOW(), userid, querytext);
		storedsearch =  NOW() || ',' || userid || ',' || querytext;
		return storedsearch;
	end;
	$$
language plpgsql;
-- select storeSearch(1, 'keyword')

drop function if exists addAnnotation(markingid int, body text);
create or replace function addAnnotation(markingid int, body text)
	returns int as $$ 
	declare
	newAnnotationId int;
	begin
		INSERT INTO annotations (markingid, body)
		VALUES (markingid, body) returning annotationid into newAnnotationId;
		return newAnnotationId;
	end;
	$$
language plpgsql;
-- select addAnnotation(1, 'hello there')

drop function if exists best_match_with_weight(VARIADIC w text[]);
drop function if exists best_match_with_weight(userId int, VARIADIC w text[]);
create or replace function best_match_with_weight(userId int, VARIADIC w text[])
returns table(questionid integer, tfidf numeric, title text) as $$
declare
	w_elem text;
	t text := 'SELECT q.questionid, sum(tfidf) rank, title FROM q_view q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
	concatSearchString text := '';
	storedSearch text;
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''' ';
	end if;
	
	if idx > 1 and idx < w_length then
		t := t || 'UNION ALL SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''' ';
	end if;	
	
	if idx = w_length then
		t := t || 'UNION ALL SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''') t WHERE q.questionid=t.id GROUP BY q.questionid, title ORDER BY rank DESC; ';
	end if;
		concatSearchString := concatSearchString || w_elem || ',';
	end loop;
  select storeSearch(userId, concatSearchString) into storedSearch;
	return query execute t;
end $$
language 'plpgsql';

-- select * from best_match_with_weight(2, 'process', 'stopped');