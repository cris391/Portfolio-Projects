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
searchdate timestamp, userid text, queryText text);


insert into comments(commentid, userid, postid, commentscore, commenttext, commentcreatedate) 
select distinct commentid, authorid, postid, commentscore, commenttext, commentcreatedate from comments_universal;

insert into app_users(username, password, salt) values 
	('user1', 'pass', 'dasadsdsa'),
	('user2', 'pass', 'dasadsdsa'),
	('user3', 'pass', 'dasadsdsa'),
	('user4', 'pass2', 'haha');

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